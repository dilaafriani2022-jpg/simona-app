@echo off
REM Test activity logging with user info from simulated app request

curl -X POST http://127.0.0.1/monak/backend/manage_siswa.php ^
  -H "Content-Type: application/json" ^
  -d "{\"action\": \"update\", \"id\": 3, \"nama_siswa\": \"Test Siswa\", \"nisn\": \"999\", \"nik\": \"999\", \"tempat_lahir\": \"Test\", \"jenis_kelamin\": \"P\", \"agama\": \"Islam\", \"status_anak\": \"Kandung\", \"anak_ke\": 1, \"tanggal_lahir\": \"2020-01-01\", \"berat_badan\": 20, \"tinggi_badan\": 120, \"alamat\": \"Test\", \"id_kelas\": 1, \"id_ortu\": 4, \"user\": {\"id\": \"1\", \"name\": \"Admin Operator\", \"role\": \"operator\"}}"

echo.
echo Checking activity log...
cd /d c:\xampp6\htdocs\monak\backend
php view_activities.php
