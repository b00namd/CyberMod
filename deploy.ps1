<#
.SYNOPSIS
    Kopiert den Mod aus src/ in die Cyberpunk-Installation oder packt ihn als ZIP.

.EXAMPLE
    .\deploy.ps1            # Mod ins Spiel kopieren (alte Version wird vorher entfernt)
    .\deploy.ps1 -Remove    # Mod aus dem Spiel entfernen
    .\deploy.ps1 -Package   # dist\AnotherCastle-<version>.zip für Nexus erstellen
#>
param(
    [string]$GamePath = "C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077",
    [switch]$Remove,
    [switch]$Package,
    [string]$Version = "0.1.0"
)

$ErrorActionPreference = "Stop"
$ModName = "AnotherCastle"
$Src = Join-Path $PSScriptRoot "src"

# Alle Ordner, die der Mod im Spielverzeichnis belegt
$ModDirs = @(
    "r6\scripts\$ModName",
    "r6\tweaks\$ModName",
    "bin\x64\plugins\cyber_engine_tweaks\mods\$ModName"
)

# Einzelne Dateien des Mods im Spielverzeichnis
$ModFiles = @(
    "archive\pc\mod\$ModName.archive"
)

# Dateien, die im Spiel entstehen und beim Deploy erhalten bleiben (im Spiel festgelegte Orte, Logs, CET-Datenbank)
$KeepFiles = @("positions.txt", "*.log", "db.sqlite3")

if ($Package) {
    $Dist = Join-Path $PSScriptRoot "dist"
    New-Item -ItemType Directory -Force $Dist | Out-Null
    $Zip = Join-Path $Dist "$ModName-$Version.zip"
    if (Test-Path $Zip) { Remove-Item $Zip }
    Compress-Archive -Path "$Src\*" -DestinationPath $Zip
    Write-Host "Paket erstellt: $Zip"
    return
}

if (-not (Test-Path "$GamePath\bin\x64\Cyberpunk2077.exe")) {
    throw "Cyberpunk 2077 nicht gefunden unter: $GamePath"
}

foreach ($dir in $ModDirs) {
    $target = Join-Path $GamePath $dir
    if (-not (Test-Path $target)) { continue }
    if ($Remove) {
        Remove-Item $target -Recurse -Force
        continue
    }
    Get-ChildItem $target -Recurse -File |
        Where-Object { $name = $_.Name; -not ($KeepFiles | Where-Object { $name -like $_ }) } |
        Remove-Item -Force
}

if ($Remove) {
    foreach ($file in $ModFiles) {
        $target = Join-Path $GamePath $file
        if (Test-Path $target) { Remove-Item $target -Force }
    }
    Write-Host "$ModName aus dem Spiel entfernt."
    return
}

# Archive sperrt das Spiel, solange es läuft: dann überspringen, alles andere trotzdem kopieren
$gameRunning = [bool](Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue)
$skipped = @()
foreach ($source in Get-ChildItem $Src -Recurse -File) {
    $rel = $source.FullName.Substring($Src.Length + 1)
    $target = Join-Path $GamePath $rel
    if ($gameRunning -and ($ModFiles -contains $rel) -and (Test-Path $target)) {
        if ((Get-FileHash $source.FullName).Hash -ne (Get-FileHash $target).Hash) { $skipped += $rel }
        continue
    }
    New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
    Copy-Item $source.FullName $target -Force
}
Write-Host "$ModName nach '$GamePath' kopiert."
foreach ($rel in $skipped) {
    Write-Warning "$rel hat sich geändert, wird aber erst nach dem Beenden des Spiels kopiert (deploy.ps1 erneut ausführen)."
}
