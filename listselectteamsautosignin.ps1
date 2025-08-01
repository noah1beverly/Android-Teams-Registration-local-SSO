# ---------------------------------------
# TeamsLogin-WithLocalDB.ps1
# ---------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Data

# — CONFIG: point to your LocalDB .mdf file —
$mdfPath = "$env:USERPROFILE\LocalDBFiles\RoomsDb.mdf"
if (-not (Test-Path $mdfPath)) {
    [System.Windows.Forms.MessageBox]::Show(
      "LocalDB file not found at:`n$mdfPath`nRun your init script first.",
      "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit
}
$connString = "Server=(localdb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$mdfPath;"

# — DATA-ACCESS HELPERS —
function Get-AllRooms {
    $rooms = [System.Collections.Generic.List[string]]::new()
    $cn = [System.Data.SqlClient.SqlConnection]::new($connString)
    try {
        $cn.Open()
        $cmd = $cn.CreateCommand()
        $cmd.CommandText = "SELECT RoomName FROM dbo.Rooms ORDER BY RoomName;"
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) { $rooms.Add($reader.GetString(0)) }
    }
    finally { $cn.Close() }
    return $rooms
}
function Get-CredsByRoom($room) {
    $obj = $null
    $cn = [System.Data.SqlClient.SqlConnection]::new($connString)
    try {
        $cn.Open()
        $cmd = $cn.CreateCommand()
        $cmd.CommandText = "SELECT Email,Password FROM dbo.Rooms WHERE RoomName=@r;"
        $param = $cmd.Parameters.Add("@r",[System.Data.SqlDbType]::NVarChar,100)
        $param.Value = $room
        $reader = $cmd.ExecuteReader()
        if ($reader.Read()) {
            $obj = [PSCustomObject]@{
                Email    = $reader.GetString(0)
                Password = $reader.GetString(1)
            }
        }
    }
    finally { $cn.Close() }
    return $obj
}

# — BUILD THE FORM —
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Teams Login"
$form.Size            = New-Object System.Drawing.Size(480,420)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox     = $false

# — Room ListBox —
$lblRoom = New-Object System.Windows.Forms.Label
$lblRoom.Text     = "Select Room:"
$lblRoom.Font     = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Regular)
$lblRoom.AutoSize = $true
$lblRoom.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($lblRoom)

$roomList = New-Object System.Windows.Forms.ListBox
$roomList.Location   = New-Object System.Drawing.Point(20,45)
$roomList.Size       = New-Object System.Drawing.Size(150,250)
$form.Controls.Add($roomList)

# — Main Header —
$mainHeader = New-Object System.Windows.Forms.Label
$mainHeader.Text     = "Enter Teams Room Credentials"
$mainHeader.Font     = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$mainHeader.AutoSize = $true
$mainHeader.Location = New-Object System.Drawing.Point(200,20)
$form.Controls.Add($mainHeader)

# — Email —
$emailLabel = New-Object System.Windows.Forms.Label
$emailLabel.Text     = "Email:"
$emailLabel.Location = New-Object System.Drawing.Point(200,65)
$emailLabel.AutoSize = $true
$form.Controls.Add($emailLabel)

$emailBox = New-Object System.Windows.Forms.TextBox
$emailBox.Location   = New-Object System.Drawing.Point(270,60)
$emailBox.Size       = New-Object System.Drawing.Size(180,22)
$emailBox.MaxLength  = 60
$form.Controls.Add($emailBox)

# — Password —
$passLabel = New-Object System.Windows.Forms.Label
$passLabel.Text     = "Password:"
$passLabel.Location = New-Object System.Drawing.Point(200,100)
$passLabel.AutoSize = $true
$form.Controls.Add($passLabel)

$passBox = New-Object System.Windows.Forms.TextBox
$passBox.Location           = New-Object System.Drawing.Point(270,95)
$passBox.Size               = New-Object System.Drawing.Size(160,22)
$passBox.UseSystemPasswordChar = $true
$passBox.MaxLength         = 40
$form.Controls.Add($passBox)

# — Eye Toggle —
$toggleButton = New-Object System.Windows.Forms.Button
$toggleButton.Location = New-Object System.Drawing.Point(435,93)
$toggleButton.Size     = New-Object System.Drawing.Size(25,23)
$toggleButton.Text     = "👁"
$toggleButton.Add_Click({
    $passBox.UseSystemPasswordChar = -not $passBox.UseSystemPasswordChar
})
$form.Controls.Add($toggleButton)

# — Secondary Header —
$codeHeader = New-Object System.Windows.Forms.Label
$codeHeader.Text     = "Enter Teams Sign in Codes"
$codeHeader.Font     = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Regular)
$codeHeader.AutoSize = $true
$codeHeader.Location = New-Object System.Drawing.Point(200,140)
$form.Controls.Add($codeHeader)

# — Tablet Code —
$tabLabel = New-Object System.Windows.Forms.Label
$tabLabel.Text     = "Tablet Code:"
$tabLabel.Location = New-Object System.Drawing.Point(180,170)
$tabLabel.AutoSize = $true
$form.Controls.Add($tabLabel)

$tabBox = New-Object System.Windows.Forms.TextBox
$tabBox.Location = New-Object System.Drawing.Point(270,165)
$tabBox.Size     = New-Object System.Drawing.Size(180,22)
$form.Controls.Add($tabBox)

# — Bar Code —
$barLabel = New-Object System.Windows.Forms.Label
$barLabel.Text     = "Bar Code:"
$barLabel.Location = New-Object System.Drawing.Point(180,205)
$barLabel.AutoSize = $true
$form.Controls.Add($barLabel)

$barBox = New-Object System.Windows.Forms.TextBox
$barBox.Location = New-Object System.Drawing.Point(270,200)
$barBox.Size     = New-Object System.Drawing.Size(180,22)
$form.Controls.Add($barBox)

# — Save & Exit Buttons —
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text     = "Save"
$saveButton.Size     = New-Object System.Drawing.Size(75,30)
$saveButton.Location = New-Object System.Drawing.Point(270,260)
$form.Controls.Add($saveButton)

$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text     = "Exit"
$exitButton.Size     = New-Object System.Drawing.Size(75,30)
$exitButton.Location = New-Object System.Drawing.Point(355,260)
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# — EVENT WIRING — #

# Populate rooms when the form is shown
$form.Add_Shown({
    $roomList.Items.Clear()
    Get-AllRooms | ForEach-Object { $roomList.Items.Add($_) | Out-Null }
})

# Helper to pull creds and update the text boxes
function Update-Credentials {
    param($sender, $e)
    $sel = $roomList.SelectedItem
    if ($sel) {
        $creds = Get-CredsByRoom $sel
        if ($creds) {
            $emailBox.Text = $creds.Email
            $passBox.Text  = $creds.Password
        }
    }
}

# Wire both events so every selection change fires updater
$roomList.Add_SelectedIndexChanged({ Update-Credentials @args })
$roomList.Add_SelectedValueChanged({ Update-Credentials @args })

# — Original Save logic continues unchanged — #
$saveButton.Add_Click({
    # 1) Gather inputs
    $email    = $emailBox.Text.Trim()
    $password = $passBox.Text
    $tablet   = $tabBox.Text.Trim()
    $barcode  = $barBox.Text.Trim()

    # 2) Validation
    if (-not ($email -match "@cgi\.com$")) {
        [System.Windows.Forms.MessageBox]::Show("Email must end with '@cgi.com'")
        return
    }
    if ($tablet.Length -lt 9) {
        [System.Windows.Forms.MessageBox]::Show("Tablet Code must be at least 9 characters")
        return
    }
    if ($barcode.Length -lt 9) {
        [System.Windows.Forms.MessageBox]::Show("Bar Code must be at least 9 characters")
        return
    }

    # 3) Store locals
    $global:Email      = $email
    $global:passW      = $password
    $global:tabletCode = $tablet
    $global:barCode    = $barcode

     # 4) Determine URL & Edge executable
    $url = "https://login.microsoftonline.com/common/oauth2/deviceauth"
    $edgeExe = "$Env:ProgramFiles (x86)\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edgeExe)) {
        $edgeExe = "$Env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
    }
    if (-not (Test-Path $edgeExe)) {
        [System.Windows.Forms.MessageBox]::Show("Microsoft Edge not found.")
        return
    }

    # ─── First InPrivate Flow ─────────────────────────────────────────
    $launchTime = Get-Date
    Start-Process -FilePath $edgeExe -ArgumentList "--inprivate","--new-window",$url
    Start-Sleep -Seconds 5

    # Paste Tablet Code → Next
    [System.Windows.Forms.Clipboard]::SetText($tablet)
    [System.Windows.Forms.SendKeys]::SendWait("^{v}")
    Start-Sleep -Seconds 2
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    # Email → Next
    Start-Sleep -Seconds 4
    [System.Windows.Forms.Clipboard]::SetText($email)
    [System.Windows.Forms.SendKeys]::SendWait("^{v}")
    Start-Sleep -Milliseconds 500
    1..4 | ForEach-Object {
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        Start-Sleep -Milliseconds 200
    }
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    # Sign in as current user
    Start-Sleep -Seconds 7
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    # Email + Password → Final
    Start-Sleep -Seconds 6
    [System.Windows.Forms.Clipboard]::SetText($email)
    [System.Windows.Forms.SendKeys]::SendWait("^{v}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.Clipboard]::SetText($password)
    [System.Windows.Forms.SendKeys]::SendWait("^{v}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 4
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 4

    # ─── Kill all edge windows ───────────────
    Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue

    # 5) Wait 5 seconds, then Second InPrivate Flow
    Start-Sleep -Seconds 15
    Start-Process -FilePath $edgeExe -ArgumentList "--inprivate","--new-window",$url
    Start-Sleep -Seconds 5

    # Paste Bar Code → Next
    [System.Windows.Forms.Clipboard]::SetText($barcode)
    [System.Windows.Forms.SendKeys]::SendWait("^{v}")
    Start-Sleep -Seconds 2
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    # ─── Inserted Email/Password Flow after Bar Code ────────────────
    Start-Sleep -Seconds 4
    [System.Windows.Forms.Clipboard]::SetText($email)
    [System.Windows.Forms.SendKeys]::SendWait("^{v}")
    Start-Sleep -Milliseconds 500
    1..4 | ForEach-Object {
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        Start-Sleep -Milliseconds 200
    }
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    Start-Sleep -Seconds 7
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    Start-Sleep -Seconds 6
    [System.Windows.Forms.Clipboard]::SetText($email)
    [System.Windows.Forms.SendKeys]::SendWait("^{v}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.Clipboard]::SetText($password)
    [System.Windows.Forms.SendKeys]::SendWait("^{v}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 4
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    # 6) Finally, close the form
    $form.Close()
})

# — LAUNCH the form — #
$form.ShowDialog()