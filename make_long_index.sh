#!/bin/bash
FILENAME=/var/www/html/index.html

if [ $# -ne 1 ]
then
echo "Missing filesize argument (size of file in kilobytes)"
exit 1
fi

if [ -f $FILENAME ]
then
  rm $FILENAME
fi
touch $FILENAME

for (( i=0; i<$1; i++))
do
  for (( j=0; j<20; j++))
  do
  	# 50 chars incl. newline
    echo "<!--This is a comment to make the file longer.-->" >> $FILENAME
  done
  # 24 chars incl. newline
  echo "<!--Another comment.-->" >> $FILENAME
done
