#!/bin/bash
#
# Dieses Skript überprüft alle .geo Files auf ihr Encoding.
# Wenn nicht UTF-8, dann konvertieren in UTF-8
#
find . -name "*.geo" -exec file --mime-encoding {} \; > liste.txt
find . -name "*.gi" -exec file --mime-encoding {} \; >> liste.txt
find . -name "*.gm4" -exec file --mime-encoding {} \; >> liste.txt
cat liste.txt | while read LINE
do
  eval x=($LINE)
#echo $LINE
echo ${x[0]::-1}
echo ${x[1]}
  if [[ ${x[1]} == *"iso-8859-1"* ]]; then
    iconv --verbose -f iso-8859-1 -t utf-8 -o ${x[0]::-1} ${x[0]::-1}
  elif [[ ${x[1]} == *"us-ascii"* ]]; then
    iconv --verbose -f us-ascii -t utf-8 -o ${x[0]::-1} ${x[0]::-1}
  fi
done
