# PowerShell script per backup delle icone attuali
# Backup Icon Script for RocketNotes AI

Write-Host "RocketNotes AI - Icon Backup Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$androidResPath = "android\app\src\main\res"
$backupPath = "backup_icons_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Verifica che siamo nella directory corretta
if (-not (Test-Path $androidResPath)) {
    Write-Host "ERRORE: Non siamo nella directory del progetto Flutter" -ForegroundColor Red
    Write-Host "Esegui questo script dalla cartella: c:\Development\RocketNotes_AI\android-app\" -ForegroundColor Yellow
    exit 1
}

# Crea cartella di backup
Write-Host "Creazione cartella di backup: $backupPath" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

# Lista delle cartelle mipmap
$mipmapFolders = @("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")

Write-Host "Backup delle icone attuali..." -ForegroundColor Yellow

foreach ($folder in $mipmapFolders) {
    $sourcePath = Join-Path $androidResPath $folder "ic_launcher.png"
    
    if (Test-Path $sourcePath) {
        $destPath = Join-Path $backupPath "$folder`_ic_launcher.png"
        Copy-Item $sourcePath $destPath
        Write-Host "  OK Backup: $folder/ic_launcher.png" -ForegroundColor Green
    } else {
        Write-Host "  WARNING Non trovato: $folder/ic_launcher.png" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Backup completato!" -ForegroundColor Green
Write-Host "File salvati in: $backupPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ora puoi sostituire le icone con la nuova immagine del calderone!" -ForegroundColor Magenta
Write-Host "Consulta ICON_UPDATE_GUIDE.md per le istruzioni complete" -ForegroundColor Cyan
