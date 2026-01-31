# Script para verificar e inicializar la estructura de directorios requerida

Write-Host "Verificando estructura de directorios..." -ForegroundColor Cyan

# Crear directorio principal de uploads
if (!(Test-Path "uploads")) {
    New-Item -ItemType Directory -Path "uploads" | Out-Null
    Write-Host "✓ Creado: uploads/" -ForegroundColor Green
} else {
    Write-Host "✓ Existe: uploads/" -ForegroundColor Gray
}

# Crear subdirectorios
$subdirs = @("facturas", "documentos_banco")
foreach ($dir in $subdirs) {
    $path = "uploads\$dir"
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "✓ Creado: $path/" -ForegroundColor Green
    } else {
        Write-Host "✓ Existe: $path/" -ForegroundColor Gray
    }
}

# Crear directorio de logs
if (!(Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
    Write-Host "✓ Creado: logs/" -ForegroundColor Green
} else {
    Write-Host "✓ Existe: logs/" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Estructura de directorios lista!" -ForegroundColor Green
Write-Host ""
Write-Host "Directorios creados:" -ForegroundColor Yellow
Write-Host "  ./uploads/" -ForegroundColor White
Write-Host "  ./uploads/facturas/" -ForegroundColor White
Write-Host "  ./uploads/documentos_banco/" -ForegroundColor White
Write-Host "  ./logs/" - ForegroundColor White
