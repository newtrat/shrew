#!/bin/bash
FILENAME=index001.html

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

# The argument gives the number of kilobytes to add
iters=$(($1*20))
for (( i=0; i<$iters; i++))
do
  echo "<!--This is a comment to make the file longer.-->" >> $FILENAME
done

mv -f $FILENAME /var/www/html/index.html
