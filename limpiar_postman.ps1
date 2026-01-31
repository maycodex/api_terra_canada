# Script para limpiar duplicados y generar versión final de Postman

$inputFile = ".\documentacion\API_Terra_Canada_v2_COMPLETA.postman_collection.json"
$outputFile = ".\documentacion\API_Terra_Canada_v2.0.0_FINAL.postman_collection.json"

Write-Host "`n🧹 LIMPIANDO DUPLICADOS..." -ForegroundColor Cyan

# Leer colección
$collection = Get-Content $inputFile -Raw -Encoding UTF8 | ConvertFrom-Json

# Función para encontrar índice de módulo
function Find-ModuleIndex {
    param($collection, $name)
    for ($i = 0; $i -lt $collection.item.Count; $i++) {
        if ($collection.item[$i].name -like "*$name*") {
            return $i
        }
    }
    return -1
}

# Función para encontrar índice de endpoint en un módulo
function Find-EndpointIndex {
    param($module, $name)
    for ($i = 0; $i -lt $module.item.Count; $i++) {
        if ($module.item[$i].name -like "*$name*") {
            return $i
        }
    }
    return -1
}

$removedCount = 0

# 1. Eliminar GET /auth/profile del módulo Authentication
$authIndex = Find-ModuleIndex $collection "Authentication"
if ($authIndex -ge 0) {
    $profileIndex = Find-EndpointIndex $collection.item[$authIndex] "Get Current User Profile"
    if ($profileIndex -ge 0) {
        $collection.item[$authIndex].item = @($collection.item[$authIndex].item | Where-Object { $_.name -ne "Get Current User Profile" })
        Write-Host "  ✅ Eliminado: GET /auth/profile" -ForegroundColor Green
        $removedCount++
    }
}

# 2. Eliminar POST /documentos/upload del módulo Documentos
$docIndex = Find-ModuleIndex $collection "Documentos"
if ($docIndex -ge 0) {
    $uploadIndex = Find-EndpointIndex $collection.item[$docIndex] "Subir Documento"
    if ($uploadIndex -ge 0) {
        $collection.item[$docIndex].item = @($collection.item[$docIndex].item | Where-Object { $_.name -ne "Subir Documento" })
        Write-Host "  ✅ Eliminado: POST /documentos/upload" -ForegroundColor Green
        $removedCount++
    }
}

# 3. Eliminar módulo completo de Facturas
$facturasIndex = Find-ModuleIndex $collection "Facturas"
if ($facturasIndex -ge 0) {
    $collection.item = @($collection.item | Where-Object { $_.name -notlike "*Facturas*" })
    Write-Host "  ✅ Eliminado: Módulo Facturas completo" -ForegroundColor Green
    $removedCount++
}

# Actualizar información de la colección
$collection.info.name = "API Terra Canada - Complete Collection v2.0.0"
$collection.info.description = "Colección completa y limpia de la API Terra Canada. Versión 2.0.0 - Todos los endpoints de Swagger incluidos, sin duplicados. Actualizado con webhooks N8N que incluyen usuario_id para trazabilidad."

# Guardar colección limpia
$collection | ConvertTo-Json -Depth 50 | Set-Content $outputFile -Encoding UTF8

Write-Host "`n📊 RESUMEN:" -ForegroundColor Cyan
Write-Host "  Duplicados eliminados: $removedCount" -ForegroundColor Yellow
Write-Host "  Módulos totales: $($collection.item.Count)" -ForegroundColor Yellow

# Contar endpoints totales
$totalEndpoints = 0
foreach ($module in $collection.item) {
    $totalEndpoints += $module.item.Count
}
Write-Host "  Endpoints totales: $totalEndpoints" -ForegroundColor Yellow

Write-Host "`n✅ COLECCIÓN FINAL GENERADA!" -ForegroundColor Green
Write-Host "  Archivo: API_Terra_Canada_v2.0.0_FINAL.postman_collection.json" -ForegroundColor Yellow

# Mostrar módulos
Write-Host "`n📋 MÓDULOS FINALES:" -ForegroundColor Cyan
foreach ($module in $collection.item) {
    Write-Host "  $($module.name): $($module.item.Count) endpoints" -ForegroundColor White
}
