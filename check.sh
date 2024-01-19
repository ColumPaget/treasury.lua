#!/bin/sh

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
rm -f /tmp/test2.value
rm -f /tmp/make_check2.lb
echo "mysekret" | ./treasury.lua export /tmp/make_check.lb -$1 /tmp/test.$1 &>/dev/null
echo "mysekret" | ./treasury.lua new /tmp/make_check2.lb &>/dev/null
echo "mysekret" | ./treasury.lua import /tmp/make_check2.lb -$1 /tmp/test.$1 
echo "mysekret" | ./treasury.lua get /tmp/make_check2.lb user@somehost -o /tmp/test2.value &>/dev/null

OutputResult /tmp/test2.value "a26bae47b08ab687b7cfbc434418f98b" "$2"
}


rm -f /tmp/test.value
rm -f /tmp/make_check.lb
echo "mysekret" | ./treasury.lua new /tmp/make_check.lb &>/dev/null
echo "mysekret" | ./treasury.lua add /tmp/make_check.lb user@somehost "my password @somehost" &>/dev/null
echo "mysekret" | ./treasury.lua add /tmp/make_check.lb foo@bar "b0rk! b0rk! b0rk! b0rk!" "chefs kiss" &>/dev/null
echo "mysekret" | ./treasury.lua get /tmp/make_check.lb user@somehost -o /tmp/test.value &>/dev/null
OutputResult /tmp/test.value "a26bae47b08ab687b7cfbc434418f98b" "Test1: create, add, get"


rm -f /tmp/test.value
echo "mysekret" | ./treasury.lua get /tmp/make_check.lb foo@bar -o /tmp/test.value &>/dev/null
OutputResult /tmp/test.value "110742d42670ae937cb1591afb5b9df0" "Test2: add with notes, get"



TestImportExport csv "Test CSV import/export"
TestImportExport json "Test JSON import/export"
TestImportExport xml "Test XML import/export"
