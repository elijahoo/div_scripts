#!/usr/bin/env bash
#
#
# Dieses Skript fragt nach der Spiegelung die Grösse des Datenbestandes ihfinanz ab und verschickt eine Mail an die eingetragenen Personen
#

DEST="elias.haefliger@swissfm.ch"
#DEST="elias.haefliger@swissfm.ch"
BETREFF="ihfinanz_size"
# 1.8GB
SIZE=1932735283

for FILENAME in /sfmtool/prg/TBARB/ihfinanz.*
do
  FILESIZE=$(stat -c%s "$FILENAME")

    if [[ $FILESIZE -gt $SIZE ]]; then

#      echo "$FILENAME is too large = $FILESIZE bytes."

mail -s $BETREFF $DEST <<EOF
Die aktuelle Groesse von ihfinanz hat das Limit ueberschritten:

`du -bhc /sfmtool/prg/TBARB/ihfinanz.*`
EOF

    fi
done
