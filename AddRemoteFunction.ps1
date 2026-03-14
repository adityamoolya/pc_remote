#AddRemoteFunction.ps1
$profilePath = $PROFILE
New-Item -ItemType Directory -Force -Path (Split-Path $profilePath) | Out-Null

#remove old version if exists
Remove-Item function:remote -ErrorAction SilentlyContinue

#add new function
Add-Content -Path $profilePath -Value @"
function remote {
    param(
        [Parameter(ValueFromRemainingArguments=`$true)]
        `$args
    )

    `$project = 'D:\test\pc_remote\'
    `$python = "`$project\venv312\Scripts\python.exe"
    `$script = "`$project\pc_server_fastapi\main.py"

    & `$python `$script @args
}
"@