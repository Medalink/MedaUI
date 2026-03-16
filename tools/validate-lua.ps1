param(
    [string]$Target = ".",
    [ValidateSet("Information", "Warning", "Error", "Hint")]
    [string]$CheckLevel = "Information",
    [switch]$Pretty
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$luaLs = "C:\Users\medal\AppData\Local\Microsoft\WinGet\Packages\LuaLS.lua-language-server_Microsoft.Winget.Source_8wekyb3d8bbwe\bin\lua-language-server.exe"
$configPath = Join-Path $repoRoot ".luarc.json"
$workspaceTarget = Join-Path $repoRoot $Target
$format = if ($Pretty) { "pretty" } else { "json" }

& $luaLs --check=$workspaceTarget --check_format=$format --checklevel=$CheckLevel --configpath=$configPath
