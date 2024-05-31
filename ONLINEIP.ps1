$outputFilePath = "output.txt"

do {
    # Kullanıcıdan IP aralığını girmesini isteyin
    $ipRange = Read-Host "Tarama yapılacak IP aralığını girin (örnek: 192.168.1)"
    while (!$ipRange -match "^\d{1,3}\.\d{1,3}\.\d{1,3}$") {
        Write-Host "Geçersiz IP aralığı. Lütfen tekrar deneyin."
        $ipRange = Read-Host "Tarama yapılacak IP aralığını girin (örnek: 192.168.1)"
    }

    $startIP = Read-Host "Başlangıç IP adresini girin (örnek: 1)"
    while (!$startIP -match "^\d{1,3}$" -or [int]$startIP -lt 1 -or [int]$startIP -gt 254) {
        Write-Host "Geçersiz başlangıç IP adresi. Lütfen 1 ile 254 arasında bir değer girin."
        $startIP = Read-Host "Başlangıç IP adresini girin (örnek: 1)"
    }

    $endIP = Read-Host "Bitiş IP adresini girin (örnek: 254)"
    while (!$endIP -match "^\d{1,3}$" -or [int]$endIP -lt [int]$startIP -or [int]$endIP -gt 254) {
        Write-Host "Geçersiz bitiş IP adresi. Lütfen başlangıç IP adresinden büyük ve 254'ten küçük bir değer girin."
        $endIP = Read-Host "Bitiş IP adresini girin (örnek: 254)"
    }

    # Tarama sonuçlarını depolamak için bir liste oluşturun
    $activeHosts = @()

    # Belirtilen IP aralığındaki her IP adresini tarayın
    foreach ($i in $startIP..$endIP) {
        $ip = "$ipRange.$i"
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($ip, 1000) # 1 saniye timeout

        if ($reply.Status -eq "Success") {
            # arp -a komutu ile MAC adresini bulun
            $arpOutput = arp -a $ip | Select-String -Pattern "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})"
            if ($arpOutput -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
                $macAddress = $matches[0]

                # https://api.macvendors.com/ API'sini kullanarak vendor bilgisini alın
                try {
                    $response = Invoke-WebRequest -Uri "https://api.macvendors.com/$macAddress" -TimeoutSec 5
                    $vendor = $response.Content
                } catch {
                    $vendor = "Bilinmiyor (API hatası)"
                }

                $activeHosts += [PSCustomObject]@{
                    IP = $ip
                    MAC = $macAddress
                    Vendor = $vendor
                }
                Write-Host "$ip aktif (MAC: $macAddress, Vendor: $vendor)"
            } else {
                Write-Host "$ip aktif (MAC bulunamadı)"
            }
        }
    }

    # Aktif bulunan cihazları listeleyin ve output.txt dosyasına ekleyin
    if ($activeHosts.Count -gt 0) {
        Write-Host "Aktif cihazlar:"
        $activeHosts | Format-Table IP, MAC, Vendor | Out-File -FilePath $outputFilePath -Append
    } else {
        "Aktif cihaz bulunamadı." | Out-File -FilePath $outputFilePath -Append
    }

    # Tekrar tarama yapmak isteyip istemediğini sorun
    $answer = Read-Host "Tekrar tarama yapmak ister misiniz? (E/H)"
} while ($answer -like "E" -or $answer -like "e")
