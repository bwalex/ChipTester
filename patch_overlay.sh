#!/bin/bash

if [ "$1" == "-d" ]; then
	dry_run=1
else
	dry_run=0
fi

dry_run=0
do_patch=0
do_overlay=0

set -- $(getopt -n $0 dop "$@")
if	[ $? -ne 0 ]
then	print >&2 "Usage: $0 [-o] [-p]"
	exit 1
fi
for o
do	case "$o" in
	-d)	dry_run=1; shift;;
	-o)	do_overlay=1; shift;;
	-p)	do_patch=1; shift;;
	--)	shift; break;;
	esac
done


_patch()
{
	submod=$1
	patch=$2
	b=$(basename $patch)

	if [ "$b" == "*" -o "$b" == "." -o "$b" == ".." ]; then
		return
	fi

	echo -n "Applying patch: $patch"
	if [ "$dry_run" == "1" ]; then
		echo " (dry run)"
	else
		echo ""
		git apply --directory=$submod $patch
	fi
}


_overlay()
{
	submod=$1
	f=$2

	b=$(basename $f)

	if [ "$b" == "*" -o "$b" == "." -o "$b" == ".." ]; then
		return
	fi

	echo -n "Overlaying: $f"
	if [ "$dry_run" == "1" ]; then
		echo " (dry run)"
	else
		echo ""
		cp -r $f $submod/
	fi
}


patch()
{
	echo "Patch stage"
	echo "------------------------------------------------------------"
	for p in patchq/*
	do
		submod=$(basename $p)
		echo "Processing $submod"

		for patch in patchq/$submod/*.patch
		do
			_patch $submod $patch
		done
	done
}


overlay()
{
	echo "Overlay stage"
	echo "------------------------------------------------------------"
	for p in overlay/*
	do
		submod=$(basename $p)
		echo "Processing $submod"

		for oly in overlay/$submod/*
		do
			_overlay $submod $oly
		done

		for oly in overlay/$submod/.*
		do
			_overlay $submod $oly
		done
	done
}


if [ "$do_patch" == "1" ]; then
	patch

	echo ""
fi


if [ "$do_overlay" == "1" ]; then
	overlay

	echo ""
fi
