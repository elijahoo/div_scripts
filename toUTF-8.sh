iconv -f ISO-8859-15 -t UTF-8 $1 > tmp.txt
mv tmp.txt $1
