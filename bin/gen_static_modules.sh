#!/bin/sh

rm -f $1
rm -f $2

for modfile in `find ../modules -name "Modules.am" -o -name "Makefile.am"`
do
    for module in `awk '/^SOURCES_/{sub(/SOURCES_/,"",$1); print $1}' "$modfile"`\
                      `awk '/^lib.*_plugin_la_SOURCES/{sub(/lib/,""); sub(/_plugin_la_SOURCES/,"",$1); print $1}' "$modfile"`
    do
        if [ -e $3/modules/.libs/lib${module}_plugin.a ]
        then
            echo "PLUGIN_INIT_SYMBOL(${module})" >> $1
            echo "vlc_LDADD += ../modules/lib${module}_plugin.la" >> $2
        fi
    done
done

touch $1 && touch $2

tmp=`mktemp`
cat $1 | sort | uniq > $tmp
cp $tmp $1
cat $2 | sort | uniq > $tmp
cp $tmp $2

rm -f $tmp
