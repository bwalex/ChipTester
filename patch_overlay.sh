#!/bin/sh

if [ "$1" == "-d" ]; then
	dry_run=1
else
	dry_run=0
fi


patch()
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


overlay()
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


echo "Patch stage"
echo "------------------------------------------------------------"
for p in patchq/*
do
	submod=$(basename $p)
	echo "Processing $submod"

	for patch in patchq/$submod/*.patch
	do
		patch $submod $patch
	done
done

echo ""

echo "Overlay stage"
echo "------------------------------------------------------------"
for p in overlay/*
do
	submod=$(basename $p)
	echo "Processing $submod"

	for oly in overlay/$submod/*
	do
		overlay $submod $oly
	done

	for oly in overlay/$submod/.*
	do
		overlay $submod $oly
	done
done
