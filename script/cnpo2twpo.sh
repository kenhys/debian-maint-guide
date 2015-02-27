#!/bin/bash
# cdluminate@gmail.com

#set -e

# check arg
if [ -z $1 ]||[ -z $2 ]; then
	echo "Usage: $0 <zh-cn.po> <zh-tw.po>"
	false
fi

# check pwd
if [ ! -e ./Makefile ]; then
	echo "Please cd into source root dir"
	false
fi

# reformat and do zh_cn -> zh_tw transform via opencc
printf "reformat... "
msgcat --no-wrap $1 | opencc -o zhcnx.po
msgcat --no-wrap $2 | opencc -o zhtwx.po

# manipulate zhcnx.po with sed script
printf "sed... "
sed -i -f script/cn2tw.sed zhcnx.po

# merge them together, and set the available translation in original
# zh_tw.po as prior.
printf "merge... "
msgcat --use-first zhtwx.po zhcnx.po -o zh_tw.new.po

# clean
rm zhcnx.po zhtwx.po
printf "done.\n"
