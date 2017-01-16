#!/bin/bash
#This script manages the folder sfmtoolwork with all his dependencies.
#Incron will be installed, if not there yet. Settings will be done.
#Some Samba Settings will be added.

sudo mkdir -p /sfmtoolwork
sudo chown -R admin:users /sfmtoolwork
mkdir -p /sfmtoolwork/prg
mkdir -p /sfmtoolwork/prg/ins
ln -sf /sfmtool/prg/ins/mandant.dat /sfmtoolwork/prg/ins/mandant.dat

if [ -d /sfmtool/tmp ]; then
	ln -sf /sfmtool/tmp /sfmtoolwork/tmp
fi

if [ -d /sfmtool/prg/cli ]; then
	ln -sf /sfmtool/prg/cli /sfmtoolwork/prg/cli
fi

if [ -d /sfmtool/prg/dok ]; then
	ln -sf /sfmtool/prg/dok /sfmtoolwork/prg/dok
fi

if [ -d /sfmtool/prg/leer ]; then
	ln -sf /sfmtool/prg/leer /sfmtoolwork/prg/leer
fi

if [ -d /sfmtool/prg/lul ]; then
	ln -s /sfmtool/prg/lul /sfmtoolwork/prg/lul
fi

if [ -f /sfmtool/prg/ins/BSSESLCR.DLL ]; then
  ln -s /sfmtool/prg/ins/BSSESLCR.DLL /sfmtoolwork/prg/ins/BSSESLCR.DLL
elif [ -f /sfmtool/prg/ins/bsseslcr.dll ]; then
  ln -s /sfmtool/prg/ins/bsseslcr.dll /sfmtoolwork/prg/ins/bsseslcr.dll
fi

# create all dirs for mandanten
smb_dont_descend="dont descend = tmp/doku"
mandanten=`ls -1 /sfmtool/prg | grep -oe '^[A-Z]\{1\}.*'`
for mand in $mandanten; do
  mkdir -p /sfmtoolwork/prg/$mand
  [ ! -L /sfmtoolwork/prg/$mand/grafik ] && ln -s /sfmtool/prg/$mand/grafik /sfmtoolwork/prg/$mand/grafik
  [ ! -L /sfmtoolwork/prg/$mand/doku ] && ln -s /sfmtool/prg/$mand/doku /sfmtoolwork/prg/$mand/doku
  smb_dont_descend="$smb_dont_descend prg/$mand/doku"
done
# following config needs to be inserted after [sfmtool]
echo $smb_dont_descend
echo -e "\nKopiere die Zeile mit 'dont descend...' und füge diese im smb.conf unter [sfmtool] hinzu.\n"
read -n1 -r -p "Press any key to continue..." key

sudo nano /etc/samba/smb.conf

# install Incron, if not yet installed.
#if [dpkg-query -l Incron != 1]; then
	#sudo apt-get update
	#sudo apt-get install Incron
#fi

# insert several lines to smb.conf.
#sed '/^[global]/a unix extensions = no' /etc/samba/smb.conf > /etc/samba/smb.conf
#sed '/^[sfmtool]/a   wide links = yes\n  #dont descend = tmp/doku' /etc/samba/smb.conf > /etc/samba/smb.conf
#sed '/^[sfmtoolwork]/a   wide links = yes\n  #dont descend = tmp/doku' /etc/samba/smb.conf > /etc/samba/smb.conf

#sudo nano /etc/incron.allow
#if [ "less /etc/incron.allow | grep 'admin'" =='' ]; then
#	sudo printf "admin" >> /etc/incron.allow
#fi
#
#if [ "incrontab -l | grep '/sfmtool/tmp/doku IN_CLOSE_WRITE,IN_MOVE bash /sfmtool/prg/opt/uti/dokucopy.sh $@/$#'" == '' ]; then
#	incrontab -e admin | printf '/sfmtool/tmp/doku IN_CLOSE_WRITE, IN_MOVE bash /sfmtool/prg/opt/uti/dokucopy.sh $@/$#'
#fi

#restart samba config
#/etc/init.d/samba reload
