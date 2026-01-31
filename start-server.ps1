# Script para iniciar el servidor API Terra Canada

Write-Host "Iniciando API Terra Canada..." -ForegroundColor Cyan

# Agregar Node.js al PATH de esta sesion
$env:Path = "C:\Program Files\nodejs;" + $env:Path

# Verificar Node.js
Write-Host "Verificando Node.js..." -ForegroundColor Green
node --version
npm --version

# Iniciar el servidor en modo desarrollo
Write-Host "Iniciando servidor en puerto 3000..." -ForegroundColor Green
Write-Host "Documentacion Swagger: http://localhost:3000/api-docs" -ForegroundColor Yellow
Write-Host "Health Check: http://localhost:3000/health" -ForegroundColor Yellow

npm run dev
