Imports System.Security.Cryptography
Imports System.Text
Imports System.Web.Configuration

''' <summary>
''' AES-256 symmetric encryption helper — mirrors Encrypt/Decrypt from PDS production.
''' Key and salt loaded from Web.config appSettings.
''' Password hashing uses SHA-256 with a per-user random salt (v2).
''' Legacy SHA-256 (no salt) is still supported for migration on first login.
''' </summary>
Module CryptoHelper

    Private ReadOnly _key As String = WebConfigurationManager.AppSettings("CryptoKey")
    Private ReadOnly _salt As String = WebConfigurationManager.AppSettings("CryptoSalt")

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
    ''' SHA-256 hash WITH a per-user salt (v2 - secure).
    ''' Use for all new passwords and when upgrading old accounts on login.
    ''' </summary>
    Public Function CreateHash(plainText As String, userSalt As String) As String
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
    ''' Legacy SHA-256 hash WITHOUT salt — used ONLY for migrating old accounts on first login.
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
