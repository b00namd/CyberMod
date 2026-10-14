<#
.SYNOPSIS
    Baut die Spieldateien des Mods aus assets\ (WolvenKit-JSON) und packt sie nach src\archive\pc\mod\AnotherCastle.archive.

.DESCRIPTION
    Benötigt WolvenKit.CLI und .NET 10 unter %LOCALAPPDATA%\AnotherCastle-tools (siehe README).
    Lucas Aussehen wird vorher mit tools\make-luca.js aus Original-Spieldateien erzeugt.
#>
$ErrorActionPreference = "Stop"

$Tools = Join-Path $env:LOCALAPPDATA "AnotherCastle-tools"
$env:DOTNET_ROOT = Join-Path $Tools "dotnet"
$Dotnet = Join-Path $Tools "dotnet\dotnet.exe"
$WolvenKit = Join-Path $Tools "WolvenKit.Console\WolvenKit.CLI.dll"

$Assets = Join-Path $PSScriptRoot "assets"
$Staging = Join-Path $Tools "build\AnotherCastle"
$Output = Join-Path $PSScriptRoot "src\archive\pc\mod"

function Invoke-WolvenKit {
    & $Dotnet $WolvenKit @args -v Minimal
    if ($LASTEXITCODE -ne 0) { throw "WolvenKit fehlgeschlagen: $args" }
}

# Handy-Kontakte/SMS aus texts\phone.json erzeugen (Vorlage: Original-Journal, einmalig mit WolvenKit entpackt)
$GameJournal = Join-Path $Tools "journal-json\cooked_journal.journal.json"
if (Test-Path $GameJournal) {
    node --max-old-space-size=4096 (Join-Path $PSScriptRoot "tools\make-journal.js") $GameJournal (Join-Path $PSScriptRoot "texts\phone.json") $Assets
    if ($LASTEXITCODE -ne 0) { throw "make-journal.js fehlgeschlagen" }
} else {
    Write-Warning "Original-Journal nicht gefunden ($GameJournal), Journal wird nicht neu erzeugt."
}

# JSON -> CR2W, mit Ordnerstruktur wie im Spiel
if (Test-Path $Staging) { Remove-Item $Staging -Recurse -Force }
foreach ($json in Get-ChildItem $Assets -Recurse -Filter *.json) {
    $relDir = Split-Path $json.FullName.Substring($Assets.Length + 1)
    $target = Join-Path $Staging $relDir
    New-Item -ItemType Directory -Force $target | Out-Null
    Invoke-WolvenKit convert deserialize $json.FullName -o $target
}

# Packen: das Archiv heißt wie der Staging-Ordner
New-Item -ItemType Directory -Force $Output | Out-Null
Invoke-WolvenKit pack $Staging -o $Output
Get-Item (Join-Path $Output "AnotherCastle.archive") | Select-Object FullName, Length
