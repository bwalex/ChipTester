#!/bin/sh


for submod in $(git submodule | cut -d ' ' -f 3); do
	pwd=$(pwd)
	spath=$(git config -f .gitmodules --get submodule.$submod.path)
	echo "Submodule: $submod ($spath)"

	if [ "$spath" == "" ]; then
		echo "Error, submodule $submod doesn't really exist"
		continue
	fi

	if [ "$1" == "clean" ]; then
		cd $spath
		git reset --hard HEAD
		git clean -f -d -x
		cd $pwd
	fi
done
