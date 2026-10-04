Imports System.Security.Cryptography
Imports System.Text
Imports System.Web.Configuration

''' <summary>
''' AES-256 symmetric encryption helper — mirrors Encrypt/Decrypt from PDS production.
''' Key and salt loaded from Web.config appSettings.
''' Password hashing versions:
'''   v1 (legacy) : SHA-256, no per-user salt  → password_salt IS NULL
'''   v2 (legacy) : SHA-256(password+salt)      → password_salt NOT NULL, hash is 64 hex chars
'''   v3 (current): PBKDF2-HMAC-SHA256          → password_salt NOT NULL, hash starts with "$pbkdf2:"
''' Migration: on successful login with v1 or v2, the hash is silently upgraded to v3.
''' TC-CM-186
''' </summary>
Module CryptoHelper

    Private ReadOnly _key  As String = WebConfigurationManager.AppSettings("CryptoKey")
    Private ReadOnly _salt As String = WebConfigurationManager.AppSettings("CryptoSalt")

    ' PBKDF2 constants (TC-CM-186)
    Private Const PBKDF2_ITERATIONS As Integer = 100000
    Private Const PBKDF2_PREFIX     As String  = "$pbkdf2:"

    ''' <summary>Encrypt a plaintext string to a URL-safe Base64 string.</summary>
    Public Function Encrypt(plainText As String) As String
        If String.IsNullOrEmpty(plainText) Then Return String.Empty
        Try
            Dim keyBytes As Byte() = GetKeyBytes()
            Using aes As Aes = Aes.Create()
                aes.Key = keyBytes
                aes.Mode = CipherMode.CBC
                aes.Padding = PaddingMode.PKCS7
                aes.GenerateIV()
                Using ms As New IO.MemoryStream()
                    ms.Write(aes.IV, 0, aes.IV.Length)
                    Using cs As New CryptoStream(ms, aes.CreateEncryptor(), CryptoStreamMode.Write)
                        Dim plainBytes As Byte() = Encoding.UTF8.GetBytes(plainText)
                        cs.Write(plainBytes, 0, plainBytes.Length)
                        cs.FlushFinalBlock()
                    End Using
                    Return Convert.ToBase64String(ms.ToArray()).Replace("+", "-").Replace("/", "_").Replace("=", "~")
                End Using
            End Using
        Catch ex As Exception
            Return String.Empty
        End Try
    End Function

    ''' <summary>Decrypt a URL-safe Base64 string back to plaintext.</summary>
    Public Function Decrypt(cipherText As String) As String
        If String.IsNullOrEmpty(cipherText) Then Return String.Empty
        Try
            Dim base64 As String = cipherText.Replace("-", "+").Replace("_", "/").Replace("~", "=")
            Dim fullBytes As Byte() = Convert.FromBase64String(base64)
            Dim keyBytes As Byte() = GetKeyBytes()
            Using aes As Aes = Aes.Create()
                aes.Key = keyBytes
                aes.Mode = CipherMode.CBC
                aes.Padding = PaddingMode.PKCS7
                Dim iv(15) As Byte
                Array.Copy(fullBytes, iv, 16)
                aes.IV = iv
                Using ms As New IO.MemoryStream(fullBytes, 16, fullBytes.Length - 16)
                    Using cs As New CryptoStream(ms, aes.CreateDecryptor(), CryptoStreamMode.Read)
                        Using sr As New IO.StreamReader(cs, Encoding.UTF8)
                            Return sr.ReadToEnd()
                        End Using
                    End Using
                End Using
            End Using
        Catch ex As Exception
            Return String.Empty
        End Try
    End Function

    ''' <summary>
    ''' Generate a cryptographically random Base64 salt string (32 bytes = 256-bit).
    ''' Call once when creating or upgrading a user's password.
    ''' </summary>
    Public Function GenerateSalt() As String
        Dim saltBytes(31) As Byte  ' 256-bit salt
        Using rng As RandomNumberGenerator = RandomNumberGenerator.Create()
            rng.GetBytes(saltBytes)
        End Using
        Return Convert.ToBase64String(saltBytes)
    End Function

    ''' <summary>
    ''' TC-CM-186: PBKDF2-HMAC-SHA256 hash with 100,000 iterations (v3 — current standard).
    ''' Stored as: "$pbkdf2:100000$&lt;Base64-derived-key&gt;"
    ''' The prefix allows unambiguous version detection on login.
    ''' </summary>
    Public Function CreatePBKDF2Hash(plainText As String, userSalt As String) As String
        Dim saltBytes As Byte() = Encoding.UTF8.GetBytes(userSalt)
        Using pdb As New Rfc2898DeriveBytes(plainText, saltBytes, PBKDF2_ITERATIONS, HashAlgorithmName.SHA256)
            Dim derivedKey As Byte() = pdb.GetBytes(32)   ' 256-bit derived key
            Return PBKDF2_PREFIX & PBKDF2_ITERATIONS.ToString() & "$" & Convert.ToBase64String(derivedKey)
        End Using
    End Function

    ''' <summary>
    ''' TC-CM-186: Primary hash entry-point. Always produces a PBKDF2 v3 hash.
    ''' Use for all new passwords and when upgrading existing accounts on login.
    ''' </summary>
    Public Function CreateHash(plainText As String, userSalt As String) As String
        Return CreatePBKDF2Hash(plainText, userSalt)
    End Function

    ''' <summary>
    ''' TC-CM-186: Verify a password against a stored hash of any version.
    ''' Returns True if the password matches regardless of hash version.
    ''' Out parameter needsUpgrade is True when the stored hash is v1 or v2
    ''' and the caller should immediately rehash using CreateHash.
    ''' </summary>
    Public Function VerifyHashedPassword(plainText As String,
                                         storedHash As String,
                                         storedSalt As String,
                                         ByRef needsUpgrade As Boolean) As Boolean
        needsUpgrade = False

        If String.IsNullOrEmpty(storedSalt) Then
            ' v1: unsalted SHA-256 (legacy — no salt column)
            needsUpgrade = True
            Return CreateLegacyHash(plainText) = storedHash
        End If

        If storedHash.StartsWith(PBKDF2_PREFIX, StringComparison.Ordinal) Then
            ' v3: PBKDF2-HMAC-SHA256 — parse iterations from stored prefix
            Try
                Dim rest As String = storedHash.Substring(PBKDF2_PREFIX.Length)
                Dim dollarPos As Integer = rest.IndexOf("$"c)
                Dim iterations As Integer = Integer.Parse(rest.Substring(0, dollarPos))
                Dim storedKeyB64 As String = rest.Substring(dollarPos + 1)
                Dim saltBytes As Byte() = Encoding.UTF8.GetBytes(storedSalt)
                Using pdb As New Rfc2898DeriveBytes(plainText, saltBytes, iterations, HashAlgorithmName.SHA256)
                    Dim candidate As String = Convert.ToBase64String(pdb.GetBytes(32))
                    Return String.Equals(candidate, storedKeyB64, StringComparison.Ordinal)
                End Using
            Catch
                Return False
            End Try
        End If

        ' v2: SHA-256(password+salt) — 64-char hex, no prefix
        ' Mark for upgrade to v3 on next successful login
        needsUpgrade = True
        Return CreateHashV2Legacy(plainText, storedSalt) = storedHash
    End Function

    ''' <summary>
    ''' Legacy SHA-256 hash WITH a per-user salt (v2).
    ''' Used ONLY inside VerifyHashedPassword for migration detection.
    ''' Do NOT call for new passwords.
    ''' </summary>
    Public Function CreateHashV2Legacy(plainText As String, userSalt As String) As String
        Dim combined As Byte() = Encoding.UTF8.GetBytes(plainText & userSalt)
        Using sha As SHA256 = SHA256.Create()
            Dim bytes As Byte() = sha.ComputeHash(combined)
            Dim sb As New StringBuilder()
            For Each b As Byte In bytes
                sb.Append(b.ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function

    ''' <summary>
    ''' Legacy SHA-256 hash WITHOUT salt — used ONLY for migrating v1 accounts on first login.
    ''' Do NOT use for new passwords.
    ''' </summary>
    Public Function CreateLegacyHash(plainText As String) As String
        Using sha As SHA256 = SHA256.Create()
            Dim bytes As Byte() = sha.ComputeHash(Encoding.UTF8.GetBytes(plainText))
            Dim sb As New StringBuilder()
            For Each b As Byte In bytes
                sb.Append(b.ToString("x2"))
            Next
            Return sb.ToString()
        End Using
    End Function

    Private Function GetKeyBytes() As Byte()
        Dim pdb As New Rfc2898DeriveBytes(_key, Encoding.UTF8.GetBytes(_salt), 1000)
        Return pdb.GetBytes(32) ' 256-bit key
    End Function

End Module
