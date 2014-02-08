#!/bin/sh
# converts all toolbox.markdown files into corresponding .html files

mkdir -p /tmp/doc
for i in *.markdown; do
 j=`basename $i .markdown`
 pandoc -f markdown -t html "$i" -o "/tmp/doc/${j}.html"
done

#konqueror file:///`pwd`/index.html &
