#!/bin/sh
ls -ARlS | grep ^[-d] | sort -rnk5 | \
# $1 file type, $5 file size, $9 file name
awk 'BEGIN { { fNum = 0 } { dNum = 0 } { tNum = 0 } }
$1 ~ /^-/ { { ++fNum } { tNum += $5 }  }
$1 ~ /^d/ { ++dNum }
NR <= 5 { print NR ":" $5 " " $9 }
END { print "Dir num: " dNum "\n" "File num:" fNum "\n" "Total: " tNum }'