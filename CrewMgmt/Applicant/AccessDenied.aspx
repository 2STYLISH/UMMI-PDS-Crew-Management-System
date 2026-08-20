<%@ Page Language="VB" Title="Access Denied" %>
<!DOCTYPE html>
<html>
<head runat="server">
    <title>Access Denied - UMMI PDS</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" />
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" />
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Inter',sans-serif; background:linear-gradient(135deg,#0f172a 0%,#1e293b 100%);
               min-height:100vh; display:flex; align-items:center; justify-content:center; color:#e2e8f0; }
        .denied-card { background:rgba(30,41,59,.85); border:1px solid rgba(248,113,113,.3);
                       border-radius:16px; padding:48px; text-align:center; max-width:480px;
                       backdrop-filter:blur(12px); box-shadow:0 25px 60px rgba(0,0,0,.4); }
        .denied-icon { font-size:56px; color:#f87171; margin-bottom:20px; animation:pulse 2s infinite; }
        .denied-title { font-size:24px; font-weight:700; color:#fca5a5; margin-bottom:12px; }
        .denied-msg { font-size:14px; color:#94a3b8; line-height:1.7; margin-bottom:24px; }
        .denied-link { display:inline-block; padding:10px 28px; background:linear-gradient(135deg,#3b82f6,#2563eb);
                       color:#fff; text-decoration:none; border-radius:8px; font-weight:600; font-size:13px;
                       transition:transform .2s,box-shadow .2s; }
        .denied-link:hover { transform:translateY(-2px); box-shadow:0 8px 20px rgba(37,99,235,.4); }
        @keyframes pulse { 0%,100%{transform:scale(1)} 50%{transform:scale(1.08)} }
    </style>
</head>
<body>
    <div class="denied-card">
        <div class="denied-icon"><i class="fa fa-shield-halved"></i></div>
        <div class="denied-title">Access Denied</div>
        <div class="denied-msg">
            The applicant encoding link you followed is <strong>invalid</strong>, <strong>expired</strong>,
            or has already been <strong>used</strong>.<br /><br />
            If you believe this is an error, please contact the Manning Office
            for a new encoding link.
        </div>
        <a href="login.aspx" class="denied-link">
            <i class="fa fa-arrow-left me-2"></i>Return to Login
        </a>
    </div>
</body>
</html>
