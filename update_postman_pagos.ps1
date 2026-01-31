# Script para actualizar la colección de Postman
# Agrega los endpoints faltantes identificados en el checklist

$collectionPath = ".\documentacion\API_Terra_Canada.postman_collection.json"
$backupPath = ".\documentacion\API_Terra_Canada.postman_collection.v2.backup.json"

# Crear backup
Copy-Item $collectionPath $backupPath -Force
Write-Host "✅ Backup creado: $backupPath" -ForegroundColor Green

# Leer colección
$collection = Get-Content $collectionPath -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "`n📊 ESTADO ACTUAL:" -ForegroundColor Cyan
Write-Host "  Módulos totales: $($collection.item.Count)" -ForegroundColor Yellow

# Encontrar módulo de Pagos
$pagosModule = $collection.item | Where-Object { $_.name -eq "9. Pagos" }
if ($pagosModule) {
    Write-Host "  Endpoints en Pagos: $($pagosModule.item.Count)" -ForegroundColor Yellow
    
    # Crear nuevos endpoints
    $newEndpoints = @()
    
    # 1. Desactivar Pago
    $newEndpoints += @{
        name = "Desactivar Pago"
        request = @{
            method = "PATCH"
            header = @()
            url = @{
                raw = "{{base_url}}/pagos/1/desactivar"
                host = @("{{base_url}}")
                path = @("pagos", "1", "desactivar")
            }
            description = "Desactiva un pago (soft delete). El pago no se elimina, solo se marca como inactivo."
        }
    }
    
    # 2. Activar Pago
    $newEndpoints += @{
        name = "Activar Pago"
        request = @{
            method = "PATCH"
            header = @()
            url = @{
                raw = "{{base_url}}/pagos/1/activar"
                host = @("{{base_url}}")
                path = @("pagos", "1", "activar")
            }
            description = "Reactiva un pago previamente desactivado."
        }
    }
    
    # 3. Documento de Estado
    $newEndpoints += @{
        name = "Enviar Documento de Estado (N8N)"
        request = @{
            method = "POST"
            header = @(
                @{
                    key = "Content-Type"
                    value = "application/json"
                }
            )
            body = @{
                mode = "raw"
                raw = @"
{
  "pdf": "JVBERi0xLjQKJeLjz9MKMSAwIG9iag...",
  "id_pago": 10,
  "usuario_id": 2
}
"@
            }
            url = @{
                raw = "{{base_url}}/pagos/documento-estado"
                host = @("{{base_url}}")
                path = @("pagos", "documento-estado")
            }
            description = "Envía documento de estado de pago a N8N. Webhook: https://n8n.salazargroup.cloud/webhook/documento_pago. Incluye usuario_id para trazabilidad."
        }
    }
    
    # 4. Subir Facturas
    $newEndpoints += @{
        name = "Subir Facturas (N8N)"
        request = @{
            method = "POST"
            header = @(
                @{
                    key = "Content-Type"
                    value = "application/json"
                }
            )
            body = @{
                mode = "raw"
                raw = @"
{
  "usuario_id": 2,
  "facturas": [
    {
      "pdf": "JVBERi0xLjQKJeLjz9MK...",
      "proveedor_id": 1
    },
    {
      "pdf": "JVBERi0xLjQKJeLjz9MK...",
      "proveedor_id": 2
    }
  ]
}
"@
            }
            url = @{
                raw = "{{base_url}}/pagos/subir-facturas"
                host = @("{{base_url}}")
                path = @("pagos", "subir-facturas")
            }
            description = "Sube hasta 3 facturas a N8N para procesamiento. Webhook: https://n8n.salazargroup.cloud/webhook/docu. Incluye usuario_id."
        }
    }
    
    # 5. Subir Extracto
    $newEndpoints += @{
        name = "Subir Extracto de Banco (N8N)"
        request = @{
            method = "POST"
            header = @(
                @{
                    key = "Content-Type"
                    value = "application/json"
                }
            )
            body = @{
                mode = "raw"
                raw = @"
{
  "pdf": "JVBERi0xLjQKJeLjz9MK...",
  "usuario_id": 2
}
"@
            }
            url = @{
                raw = "{{base_url}}/pagos/subir-extracto-banco"
                host = @("{{base_url}}")
                path = @("pagos", "subir-extracto-banco")
            }
            description = "Sube extracto bancario a N8N para procesamiento. Webhook: https://n8n.salazargroup.cloud/webhook/docu. Incluye usuario_id."
        }
    }
    
    # Agregar nuevos endpoints
    foreach ($endpoint in $newEndpoints) {
        $pagosModule.item += $endpoint
    }
    
    Write-Host "`n✅ Agregados 5 endpoints al módulo de Pagos" -ForegroundColor Green
}

# Guardar colección actualizada
$collection | ConvertTo-Json -Depth 50 | Set-Content $collectionPath -Encoding UTF8

Write-Host "`n📊 ESTADO FINAL:" -ForegroundColor Cyan
Write-Host "  Endpoints en Pagos: $($pagosModule.item.Count)" -ForegroundColor Yellow
Write-Host "`n✅ Colección actualizada exitosamente!" -ForegroundColor Green
