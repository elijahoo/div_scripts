:: Dieses Skript stuft das SWISSFM Tool lokal auf dem Computer als vertrauenswürdig ein
:: Nicht benötigte IP-Adressen müssen auskommentiert werden!
:: Weitere IP-Adressen können auch hinzugefügt werden.

set SWISSFM="192.168.10.13"
set BASF="192.168.10.182"

REG ADD "HKcU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\192.168.10.182" /V "*" /t REG_DWORD /D 1 /f
REG ADD "HKcU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges\192.168.10.182" /V ":Range" /t REG_SZ /D 192.168.10.182 /f


