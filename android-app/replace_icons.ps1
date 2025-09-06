# 🎨 RocketNotes AI - Script Sostituzione Icone
# Questo script automatizza la sostituzione delle icone dell'app

Write-Host "🚀 RocketNotes AI - Sostituzione Icone Automatica" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Yellow

# Percorsi
$androidAppPath = "c:\Development\RocketNotes_AI\android-app"
$iconBasePath = "$androidAppPath\android\app\src\main\res"
$backupPath = "$androidAppPath\backup_icons_manual"

# Densità e dimensioni
$densities = @{
    "mipmap-mdpi" = "48x48"
    "mipmap-hdpi" = "72x72" 
    "mipmap-xhdpi" = "96x96"
    "mipmap-xxhdpi" = "144x144"
    "mipmap-xxxhdpi" = "192x192"
}

Write-Host "📁 Controllo struttura cartelle..." -ForegroundColor Cyan

# Controlla se esistono le cartelle mipmap
$allFoldersExist = $true
foreach ($density in $densities.Keys) {
    $folderPath = "$iconBasePath\$density"
    if (-not (Test-Path $folderPath)) {
        Write-Warning "❌ Cartella mancante: $folderPath"
        $allFoldersExist = $false
    } else {
        Write-Host "✅ Trovata: $folderPath" -ForegroundColor Green
    }
}

if (-not $allFoldersExist) {
    Write-Host "❌ Alcune cartelle mipmap sono mancanti. Creazione in corso..." -ForegroundColor Red
    foreach ($density in $densities.Keys) {
        $folderPath = "$iconBasePath\$density"
        if (-not (Test-Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force
            Write-Host "✅ Creata: $folderPath" -ForegroundColor Green
        }
    }
}

# Funzione per sostituire un'icona
function Set-Icon {
    param(
        [string]$SourcePath,
        [string]$TargetDensity,
        [string]$ExpectedSize
    )
    
    $targetPath = "$iconBasePath\$TargetDensity\ic_launcher.png"
    
    if (Test-Path $SourcePath) {
        try {
            Copy-Item $SourcePath $targetPath -Force
            Write-Host "✅ Sostituita icona $TargetDensity ($ExpectedSize)" -ForegroundColor Green
            return $true
        } catch {
            Write-Warning "❌ Errore sostituendo $TargetDensity`: $_"
            return $false
        }
    } else {
        Write-Warning "❌ File sorgente non trovato: $SourcePath"
        return $false
    }
}

# Menu principale
$choice = ""
while ($choice -ne "7") {
    Write-Host "`n🎨 MENU SOSTITUZIONE ICONE" -ForegroundColor Yellow
    Write-Host "1. 📥 Sostituisci icone da cartella Downloads"
    Write-Host "2. 📁 Sostituisci icone da percorso personalizzato"
    Write-Host "3. 🔙 Ripristina icone originali dal backup"
    Write-Host "4. 🌐 Apri generatore icone HTML"
    Write-Host "5. 🔍 Verifica icone attuali"
    Write-Host "6. 🏗️  Ricostruisci app (flutter clean + build)"
    Write-Host "7. ❌ Esci"
    
    $choice = Read-Host "`nScegli un'opzione (1-7)"
    
    if ($choice -eq "1") {
        Write-Host "`n📥 Ricerca icone in Downloads..." -ForegroundColor Cyan
        $downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
        
        $iconsFound = @{}
        foreach ($density in $densities.Keys) {
            $size = $densities[$density]
            $possibleNames = @(
                "ic_launcher_$size.png",
                "ic_launcher_${density}.png",
                "icon_$size.png",
                "cauldron_$size.png"
            )
            
            foreach ($name in $possibleNames) {
                $filePath = "$downloadsPath\$name"
                if (Test-Path $filePath) {
                    $iconsFound[$density] = $filePath
                    Write-Host "✅ Trovata: $name per $density" -ForegroundColor Green
                    break
                }
            }
        }
        
        if ($iconsFound.Count -gt 0) {
            Write-Host "`n🔄 Sostituzione icone trovate..." -ForegroundColor Yellow
            foreach ($density in $iconsFound.Keys) {
                $size = $densities[$density]
                Set-Icon $iconsFound[$density] $density $size
            }
            Write-Host "✅ Sostituzione completata!" -ForegroundColor Green
        } else {
            Write-Warning "❌ Nessuna icona trovata in Downloads"
            Write-Host "💡 Suggerimento: Scarica le icone dal generatore HTML prima" -ForegroundColor Yellow
        }
    }
    elseif ($choice -eq "2") {
        $customPath = Read-Host "`n📁 Inserisci il percorso della cartella con le icone"
        if (Test-Path $customPath) {
            Write-Host "🔍 Ricerca icone in: $customPath" -ForegroundColor Cyan
            
            $iconsFound = @{}
            foreach ($density in $densities.Keys) {
                $size = $densities[$density]
                $possibleNames = @(
                    "ic_launcher_$size.png",
                    "ic_launcher_${density}.png", 
                    "icon_$size.png",
                    "$density.png"
                )
                
                foreach ($name in $possibleNames) {
                    $filePath = "$customPath\$name"
                    if (Test-Path $filePath) {
                        $iconsFound[$density] = $filePath
                        Write-Host "✅ Trovata: $name per $density" -ForegroundColor Green
                        break
                    }
                }
            }
            
            if ($iconsFound.Count -gt 0) {
                foreach ($density in $iconsFound.Keys) {
                    $size = $densities[$density]
                    Set-Icon $iconsFound[$density] $density $size
                }
            } else {
                Write-Warning "❌ Nessuna icona riconosciuta trovata"
            }
        } else {
            Write-Warning "❌ Percorso non valido"
        }
    }
    elseif ($choice -eq "3") {
        Write-Host "`n🔙 Ripristino icone originali..." -ForegroundColor Cyan
        if (Test-Path $backupPath) {
            $backupFiles = Get-ChildItem "$backupPath\*.png"
            if ($backupFiles.Count -gt 0) {
                foreach ($density in $densities.Keys) {
                    $backupFile = "$backupPath\ic_launcher_$density.png"
                    if (Test-Path $backupFile) {
                        $targetPath = "$iconBasePath\$density\ic_launcher.png"
                        Copy-Item $backupFile $targetPath -Force
                        Write-Host "✅ Ripristinata: $density" -ForegroundColor Green
                    }
                }
                Write-Host "✅ Ripristino completato!" -ForegroundColor Green
            } else {
                Write-Warning "❌ Nessun backup trovato"
            }
        } else {
            Write-Warning "❌ Cartella backup non trovata"
        }
    }
    elseif ($choice -eq "4") {
        Write-Host "`n🌐 Apertura generatore icone..." -ForegroundColor Cyan
        $htmlPath = "$androidAppPath\icon_generator.html"
        if (Test-Path $htmlPath) {
            Start-Process $htmlPath
            Write-Host "✅ Generatore aperto nel browser" -ForegroundColor Green
        } else {
            Write-Warning "❌ File generatore non trovato"
        }
    }
    elseif ($choice -eq "5") {
        Write-Host "`n🔍 Verifica icone attuali..." -ForegroundColor Cyan
        foreach ($density in $densities.Keys) {
            $iconPath = "$iconBasePath\$density\ic_launcher.png"
            $size = $densities[$density]
            
            if (Test-Path $iconPath) {
                $fileInfo = Get-Item $iconPath
                $fileSizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
                Write-Host "✅ $density ($size): $fileSizeKB KB - $($fileInfo.LastWriteTime)" -ForegroundColor Green
            } else {
                Write-Host "❌ $density ($size): MANCANTE" -ForegroundColor Red
            }
        }
    }
    elseif ($choice -eq "6") {
        Write-Host "`n🏗️ Ricostruzione app Flutter..." -ForegroundColor Cyan
        Set-Location $androidAppPath
        
        Write-Host "🧹 Esecuzione flutter clean..." -ForegroundColor Yellow
        flutter clean
        
        Write-Host "🔨 Esecuzione flutter build apk..." -ForegroundColor Yellow
        flutter build apk
        
        Write-Host "✅ Ricostruzione completata!" -ForegroundColor Green
    }
    elseif ($choice -eq "7") {
        Write-Host "`n👋 Arrivederci!" -ForegroundColor Green
        break
    }
    else {
        Write-Warning "❌ Opzione non valida. Riprova."
    }
    
    if ($choice -ne "7") {
        Read-Host "`nPremi Enter per continuare..."
    }
}

Write-Host "`n🎉 Script completato!" -ForegroundColor Green
