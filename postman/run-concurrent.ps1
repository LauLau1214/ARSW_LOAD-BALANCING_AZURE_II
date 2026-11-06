# Lanza N ejecuciones de Newman en paralelo contra la Function y resume los resultados.
# Uso:  .\run-concurrent.ps1            (10 concurrentes, 1 iteracion cada una)
#       .\run-concurrent.ps1 -Concurrent 4 -Iterations 3
param(
    [int]$Concurrent = 10,
    [int]$Iterations = 1
)

$dir = $PSScriptRoot
$newman = (Get-Command newman.cmd).Source
$out = Join-Path $dir "results"
New-Item -ItemType Directory -Force $out | Out-Null
Remove-Item "$out\run_*.json" -ErrorAction SilentlyContinue

Write-Host "Lanzando $Concurrent ejecuciones concurrentes de Newman ($Iterations iteracion(es) cada una)..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$jobs = 1..$Concurrent | ForEach-Object {
    Start-Job -ArgumentList $newman, $dir, $out, $_, $Iterations -ScriptBlock {
        param($newman, $dir, $out, $i, $iterations)
        & $newman run "$dir\Fibonacci_Function.postman_collection.json" `
            -e "$dir\Fibonacci_Function.postman_environment.json" `
            -n $iterations --reporters json --reporter-json-export "$out\run_$i.json" | Out-Null
    }
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
$sw.Stop()

$rows = 1..$Concurrent | ForEach-Object {
    $file = "$out\run_$_.json"
    if (Test-Path $file) {
        $run = (Get-Content $file -Raw | ConvertFrom-Json).run
        [pscustomobject]@{
            Ejecucion   = $_
            Peticiones  = $run.stats.requests.total
            Fallidas    = $run.stats.requests.failed
            'Prom (s)'  = [math]::Round($run.timings.responseAverage / 1000, 1)
            'Min (s)'   = [math]::Round($run.timings.responseMin / 1000, 1)
            'Max (s)'   = [math]::Round($run.timings.responseMax / 1000, 1)
            'Duracion (s)' = [math]::Round(($run.timings.completed - $run.timings.started) / 1000, 1)
        }
    } else {
        [pscustomobject]@{ Ejecucion = $_; Peticiones = 0; Fallidas = 'sin resultado'; 'Prom (s)' = $null; 'Min (s)' = $null; 'Max (s)' = $null; 'Duracion (s)' = $null }
    }
}

$rows | Format-Table -AutoSize
$total = ($rows | Measure-Object Peticiones -Sum).Sum
$fail = ($rows | Where-Object { $_.Fallidas -is [int] } | Measure-Object Fallidas -Sum).Sum
Write-Host ("Total: {0} peticiones, {1} fallidas. Tiempo total de pared: {2:N1} s" -f $total, $fail, $sw.Elapsed.TotalSeconds)
