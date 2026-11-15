$ErrorActionPreference = 'Stop'

$postgresBin = 'C:\Program Files\PostgreSQL\18\bin'
$clusterPath = Join-Path $env:LOCALAPPDATA 'StockMate\pgdata'
$postgresLog = Join-Path $env:LOCALAPPDATA 'StockMate\postgres.log'
$pgCtl = Join-Path $postgresBin 'pg_ctl.exe'

if (-not (Test-Path -LiteralPath $clusterPath)) {
    throw "StockMate database cluster not found: $clusterPath"
}

& $pgCtl -D $clusterPath status *> $null
if ($LASTEXITCODE -ne 0) {
    & $pgCtl -D $clusterPath -l $postgresLog -o '-h 127.0.0.1 -p 5433 -c shared_buffers=64MB -c max_connections=20 -c work_mem=2MB -c maintenance_work_mem=16MB' -w start
    if ($LASTEXITCODE -ne 0) { throw 'Could not start StockMate PostgreSQL.' }
}

$listener = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Host 'StockMate API is already listening on port 8000.'
    exit 0
}

$env:DEBUG = 'false'
$python = Join-Path $PSScriptRoot 'backend\.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) {
    throw 'Backend virtual environment is missing. Install backend/requirements.lock.txt first.'
}

Push-Location (Join-Path $PSScriptRoot 'backend')
try {
    & $python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
} finally {
    Pop-Location
}
