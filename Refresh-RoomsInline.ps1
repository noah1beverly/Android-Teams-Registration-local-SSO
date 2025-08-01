# 1) Locate CSV
$csvPath = Join-Path $PSScriptRoot 'RoomsToSeed.csv'
if (-not (Test-Path $csvPath)) {
    Write-Error "Could not find $csvPath"
    exit 1
}

# 2) Truncate the table
Write-Host "🗑 Truncating dbo.Rooms..."
sqlcmd -S '(localdb)\MSSQLLocalDB' -d RoomsDb -Q "TRUNCATE TABLE dbo.Rooms;"

# 3) Import CSV and INSERT row by row
Write-Host "✏️ Inserting rows from CSV..."
Import-Csv $csvPath | ForEach-Object {
    # Escape any single-quotes
    $rn = $_.RoomName  -replace("'","''")
    $em = $_.Email     -replace("'","''")
    $pw = $_.Password  -replace("'","''")

    $insertQ = "
INSERT INTO dbo.Rooms (RoomName,Email,Password)
VALUES (N'$rn', N'$em', N'$pw');
"
    sqlcmd -S '(localdb)\MSSQLLocalDB' -d RoomsDb -Q $insertQ | Out-Null
    Write-Host "  • Inserted '$($_.RoomName)'"
}

# 4) Verify contents
Write-Host "`n🔍 Final contents of dbo.Rooms:"
sqlcmd -S '(localdb)\MSSQLLocalDB' -d RoomsDb -Q "SET NOCOUNT ON; SELECT RoomName, Email, Password FROM dbo.Rooms ORDER BY RoomName;"