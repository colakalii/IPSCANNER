# IP Scan Script

Here we are, the first scripts and official repo from me.

I'll immediately cut the trash talking. Let me explain what these two scripts does:

ONLINEIP.ps1:

With this script you can locally scan your network. You can specify the block such as "192.168.1" at first. And after it will ask you which number to start from the scan such as "1" or "67". It's up to your needings. Second it will ask you the last number like before. If we think you specified the block as "192.168.1" and first number "1" last number "10" the script will scan between "192.168.1.1" to "192.168.1.10". If there is activity exists it will return "192.168.1.1 active (Mac:*****, Vendor *******). But remember, if you dont have MS Edge or deleted it from system somehow the api will return with API Error on powershell. At the end it will ask you do you want to scan again if you need. If you do scan again will return the output to the same file but under the previous scan results.

OFFLINEIP.ps1:

This is literally the same one but without online API's. You need the "mac-vendor.txt" file (which i took from https://gist.github.com/aallan) for the correct vendor results. 

Both these scripts written with Gemini Advanced. Thanks to that :).

Enjoy.
