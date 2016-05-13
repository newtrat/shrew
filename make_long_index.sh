#!/bin/bash
if [ -f index.html ]
then
  rm index.html
fi
touch index.html

# The argument gives the number of kilobytes to add
iters=$(($1*20))
for (( i=0; i<$iters; i++))
do
  echo "<!--This is a comment to make the file longer.-->" >> index.html
done

mv -f index.html /var/www/html/index.html
