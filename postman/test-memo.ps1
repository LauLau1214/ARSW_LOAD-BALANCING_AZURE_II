# Llama varias veces a la funcion con memoization y muestra si respondio desde cache.
# Uso:  .\test-memo.ps1                    (3 llamadas con nth=20000)
#       .\test-memo.ps1 -Nth 15000 -Calls 5
param(
    [int]$Nth = 20000,
    [int]$Calls = 3
)

$url = "https://fuctionprojectfibonacci-ehbrabaubhfebgdg.eastus2-01.azurewebsites.net/api/fibonaccimemo"

$rows = 1..$Calls | ForEach-Object {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body (@{ nth = $Nth } | ConvertTo-Json)
    $sw.Stop()
    [pscustomobject]@{
        '#'          = $_
        Hora         = (Get-Date).ToString("HH:mm:ss")
        Cache        = $r.cached
        'Calc ms'    = $r.computeMs
        'HTTP ms'    = [math]::Round($sw.Elapsed.TotalMilliseconds)
        Entradas     = $r.cacheEntries
        'Uptime s'   = $r.instanceUptimeSeconds
        Instancia    = $r.instance
    }
    Start-Sleep -Seconds 1
}

$rows | Format-Table -AutoSize
