#!/bin/sh

TEST_DIR=/tmp/.treasury_make_check/

function OutputResult
{
local MD5

MD5=`md5sum "$1" | cut -d ' ' -f 1`

if [ "$MD5" = "$2" ]
then 
				echo "$3 OKAY"
else
				echo "$3 FAILED"
fi

}


function TestImportExport
{
rm -f $TEST_DIR/test2.value
rm -f $TEST_DIR/make_check2.lb
echo "mysekret" | ./treasury.lua export $TEST_DIR/make_check.lb -$1 $TEST_DIR/test.$1 &>/dev/null
echo "mysekret" | ./treasury.lua new $TEST_DIR/make_check2.lb &>/dev/null
echo "mysekret" | ./treasury.lua import $TEST_DIR/make_check2.lb -$1 $TEST_DIR/test.$1 &>/dev/null
echo "mysekret" | ./treasury.lua get $TEST_DIR/make_check2.lb user@somehost -o $TEST_DIR/test2.value &>/dev/null

OutputResult $TEST_DIR/test2.value "a26bae47b08ab687b7cfbc434418f98b" "$2"
}


rm -f $TEST_DIR/test.value
rm -f $TEST_DIR/make_check.lb
echo "mysekret" | ./treasury.lua new $TEST_DIR/make_check.lb &>/dev/null
echo "mysekret" | ./treasury.lua add $TEST_DIR/make_check.lb user@somehost "my password @somehost" &>/dev/null
echo "mysekret" | ./treasury.lua add $TEST_DIR/make_check.lb foo@bar "b0rk! b0rk! b0rk! b0rk!" "chefs kiss" &>/dev/null
echo "mysekret" | ./treasury.lua get $TEST_DIR/make_check.lb user@somehost -o $TEST_DIR/test.value &>/dev/null
OutputResult $TEST_DIR/test.value "a26bae47b08ab687b7cfbc434418f98b" "Test: create, add, get"


rm -f $TEST_DIR/test.value
echo "mysekret" | ./treasury.lua get $TEST_DIR/make_check.lb foo@bar -o $TEST_DIR/test.value &>/dev/null
OutputResult $TEST_DIR/test.value "110742d42670ae937cb1591afb5b9df0" "Test: add with notes, get"

rm -f $TEST_DIR/test.png
echo "mysekret" | ./treasury.lua get $TEST_DIR/make_check.lb foo@bar -qr -o $TEST_DIR/test.png &>/dev/null
OutputResult $TEST_DIR/test.png "655e3cda1e11e90f833658ab59c6a8f2" "Test: write output as qr code PNG"


TestImportExport csv "Test: CSV import/export"
TestImportExport json "Test: JSON import/export"
TestImportExport xml "Test: XML import/export"

rm -rf $TEST_DIR
