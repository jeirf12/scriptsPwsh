# Script PowerShell para analizar archivo CSV con filtro de autorización específico

$logFilePath = "log.csv"  # Actualiza con la ruta de tu archivo
$output_file = "log_results.txt"
$results = @()

# Importar el archivo CSV sin cabeceras
$csvData = Import-Csv -Path $logFilePath -Header "Timestamp", "Message"

foreach ($row in $csvData) {
    $timestamp = $row.Timestamp
    $message = $row.Message
    
        $entryData = @{
            Timestamp = $timestamp
        }
        
        # Extraer OrderCode
        $orderCodeMatch = [regex]::Match($message, '"OrderCode":(\d+)')
        if ($orderCodeMatch.Success) {
            $entryData['OrderCode'] = $orderCodeMatch.Groups[1].Value
        }
        
        # Extraer Tags - mejorado para capturar todos los formatos posibles
        $tagsMatch = [regex]::Match($message, '"Tags":\s*\[(.*?)\]', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($tagsMatch.Success) {
            # $entryData['Booking'] = $tagsMatch.Groups[1].Value
            $tagsText = $tagsMatch.Groups[1].Value.Trim()
            # Si hay tags, procesarlos
            if ($tagsText) {
                # Extraer tags con manejo adecuado de comillas
                $tagMatches = [regex]::Matches($tagsText, '"([^"\\]*(?:\\.[^"\\]*)*)"')
                if ($tagMatches.Count -gt 0) {
                    $tags = @()
                    foreach ($match in $tagMatches) {
                        $tags += $match.Groups[1].Value
                    }
                    $entryData['Booking'] = $tags
                } else {
                    # Alternativa si no hay comillas
                    $entryData['Booking'] = $tagsText -split ',' | ForEach-Object { $_.Trim('"', ' ') }
                }
            } else {
                $entryData['Booking'] = @()
            }
        }
        
        # Extraer X-Viva-Correlationid
        $correlationMatch = [regex]::Match($message, '"X-Viva-Correlationid","Value":"([^"]+)"')
        if ($correlationMatch.Success) {
            $entryData['X-Viva-Correlationid'] = $correlationMatch.Groups[1].Value
        }
        
        # Buscar posible fecha de expiración en tokens
        $expMatch = [regex]::Match($message, '"ExpirationDate":"([^"]+)"')
        if ($expMatch.Success) {
            $entryData['ExpirationDate'] = $($expMatch.Groups[1].Value)
        }
        
        # Si encontramos un OrderCode, agregamos esta entrada a nuestros resultados
        if ($entryData.ContainsKey('OrderCode')) {
            $results += [PSCustomObject]$entryData
        }
}

# Mostrar resultados
if ($results.Count -gt 0) {
    Write-Host "Encontrados $($results.Count) registros de log:"
    $index = 1
    foreach ($entry in $results) {
        Write-Host "`nRegistro ${index}:"
        Write-Host "  Timestamp: $($entry.Timestamp)"
        Write-Host "  OrderCode: $($entry.OrderCode)"
        Write-Host "  Booking Code/Flow: $($entry.Booking)"
        Write-Host "  ExpirationDate: $(if ($entry.ExpirationDate) { $entry.ExpirationDate } else { 'No encontrado' })"
        Write-Host "  X-Viva-Correlationid: $(if ($entry.'X-Viva-Correlationid') { $entry.'X-Viva-Correlationid' } else { 'No encontrado' })"
        $index++
    }

    $results | ForEach-Object {
        $output = "Registro $($_.Timestamp):"
        $output += "`n  OrderCode: $($_.OrderCode)"
        $output += "`n  Tags: $($_.Tags -join ', ')"
        $output += "`n  ExpirationDate: $($_.ExpirationDate)"
        $output += "`n  X-Viva-Correlationid: $($_.'X-Viva-Correlationid')"
        $output += "`n"
        $output | Out-File -Append -FilePath $outputFilePath
    }
} else {
    Write-Host "No se encontraron registros de log que coincidan con el criterio de autorización."
}
