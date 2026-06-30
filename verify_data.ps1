$response = Invoke-WebRequest -Uri 'http://127.0.0.1/monak/backend/manage_siswa.php' -UseBasicParsing
$data = $response.Content | ConvertFrom-Json

Write-Host "=== Verifikasi Siswa & Orang Tua ===" -ForegroundColor Green
Write-Host ""

$data.data | ForEach-Object {
    $no = [array]::IndexOf($data.data, $_) + 1
    Write-Host "$no. $($_.nama_siswa)" -ForegroundColor Cyan
    Write-Host "   └─ Orang Tua: $($_.nama_ortu)" -ForegroundColor Yellow
    Write-Host "   └─ Email: $($_.email_ortu)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Total Siswa: $($data.data.Count)" -ForegroundColor Green
