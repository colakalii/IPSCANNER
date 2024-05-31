$outputFilePath = "output.txt"
$macVendorFilePath = "mac-vendor.txt"

# mac-vendor.txt dosyasını yükle
$macVendorData = Get-Content $macVendorFilePath | Where-Object { $_ -notmatch "^#" } # Yorum satırlarını atla

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

         # MAC adresinin ilk 6 hanesini (OUI) al
        $oui = $macAddress.Substring(0, 8).Replace("-", "").ToUpper()

        # mac-vendor.txt dosyasında OUI'yi ara ve vendor bilgisini daha esnek bir şekilde ayrıştır
        $vendor = $macVendorData | Where-Object { $_.StartsWith($oui) } | Select-Object -First 1
        if ($vendor) {
            $vendorParts = $vendor -split '\s+' # Tüm boşluk karakterlerine göre böl
            $vendor = $vendorParts[0..($vendorParts.Length - 1)] -join ' ' # İlk parçadan son parçaya kadar olanları birleştir (OUI dahil)
        } else {
            $vendor = "Bilinmiyor"
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
