title: treasury.lua
mansection: 1
date: 05 April 2024

SYNOPSIS
========

treasury.lua is a simple command-line app for storing short secrets.


DESCRIPTION
===========

*treasury.lua* is intended for storing short secrets like phone numbers, contact details, or passwords. It uses the openssl command-line app to encrypt data, which is then stored in 'lockboxes' (which are single files containing all items related to a given task or data type). Each lockbox is password-protected, and has an optional password hint that it will display when querying for it's password.

*treasury.lua* can export it's data in a few simple formats, can generate qr codes from data, and can generate TOTP authentication codes from stored data too.


USAGE
=====

```
 treasury.lua [action] [lockbox] [key] [value]
```


ACTIONS
=======

new [lockbox]
: create a new lockbox

list [lockbox]
: list keys in a lockbox, along with their associated notes/comment

names [lockbox]
: list keys in a lockbox

dump [lockbox]
: dump lockbox in plain text

add [lockbox] [key] [value]
: add a key/value pair to a lockbox

add [lockbox] [key] -g
: generate a 32bit random string, and add it to a lockbox

add [lockbox] [key] -generate
: generate a 32bit random string, and add it to a lockbox

add [lockbox] [key] -glen <len>
: generate a random string, and add it to a lockbox

del [lockbox] [key]
: remove a key/value pair from a lockbox

rm  [lockbox] [key]
: remove a key/value pair from a lockbox

get [lockbox] [key]
: get the value matching "key" in a lockbox

get [lockbox] [key] -o <path>
: get the value matching "key" in a lockbox, and write it to <path>

get [lockbox] [key] -qr
: get the value matching "key" in a lockbox, and display as qr code

get [lockbox] [key] -qr -o <path>
: get the value matching "key" in a lockbox, and write as a qr code PNG to <path>

get [lockbox] [key] -clip
: get the value matching "key" in a lockbox, and push it to clipboard

get [lockbox] [key] -osc52
: get the value matching "key" in a lockbox, and push it to clipboard using xterm"s osc52 command

get [lockbox] [key] -totp
: get the value matching "key" in a lockbox, use it to generate a google-authenticator compatible TOTP code.

entry [lockbox]
: enter "data entry" mode for lockbox

shell [lockbox]
: enter "shell" mode for lockbox

chpw [box]
: change password for a lockbox

find [lockbox] [search pattern]
: find key/value pairs matching "search pattern"

update
: sync known lockboxes by searching for matching "sync" files found in the "sync_in" directory (default ~/.treasury/sync_in)

update [lockbox]
: sync specified known lockbox by searching for matching "sync" files found in the "sync_in" directory (default ~/.treasury/sync_in)

sync
: sync key/value pairs from "sync" files found in the "sync_in" directory (default ~/.treasury/sync_in)

sync [path]
: sync key/value pairs from a sync or lockbox file(s). "path" can be a pattern like "/home/user/incoming/*", or an ssh path like "ssh:myserver/sync/treasury/*.sync"

sync [path] [path] ...
: sync key/value pairs from a sync or lockbox file(s). "path" can be a pattern like "/home/user/incoming/*", or an ssh path like "ssh:myserver/sync/treasury/*.sync"

send [path] [dir]
: send lockbox at <path> to a directory <dir> for syncing. <dir> can be an ssh: url to a directory on another system

send [dir]
: send all known lockboxes to a directory <dir> for syncing. <dir> can be an ssh: url to a directory on another system

sync-status
: display details of last imports of 'sync' files

import [lockbox] [path]
:         import key/value pairs from a file

export [lockbox] [path]
:         export key/value pairs to a file

export [lockbox] [path] -csv
:    export key/value pairs from a csv file

export [lockbox] [path] -xml
:    export key/value pairs from a xml file

export [lockbox] [path] -json
:   export key/value pairs from a json file

export [lockbox] [path] -zcsv
:   export key/value pairs from a pkzipped csv file (with password)

export [lockbox] [path] -zxml
:   export key/value pairs from a pkzipped xml file (with password)

export [lockbox] [path] -zjson
:  export key/value pairs from a pkzipped json file (with password)

export [lockbox] [path] -7zcsv
:  export key/value pairs from a 7zipped csv file (with password)

export [lockbox] [path] -7zxml
:  export key/value pairs from a 7zipped xml file (with password)

export [lockbox] [path] -7zjson
: export key/value pairs from a 7zipped json file (with password)

show-config
: print out application config

config-set [name] [value]
: change a config value

version
: print program version

-version
: print program version

--version
: print program version

--help
: print help

-help
: print help

help
: print help

-?
: print help





OPTIONS
=======

Note, the below options are generally used with specific actions listed above. "data" mentioned below refers to the secret data that is stored in a lockbox against a key


-K 
: don't use keyring for getting lockbox password

-nokeyring
: don't use keyring for getting lockbox password

-nosync
: don't update a lockbox with files from the "sync_in" directory before names/list/dump/get commands

-g
: generate a 32bit random string, and add it to a lockbox, used to generate random passwords

-generate
: generate a 32bit random string, and add it to a lockbox, used to generate random passwords

-glen <len>
: generate a random string of length <len>, and add it to a lockbox, used to generate random passwords

-o <path>
: write output to file at 'path' instead of stdout. Usually this writes the secret data to a file, but can be used with "-qr" to write a qrcode to a file.

-qr
: generate qr code of data for a given key

-clip
: push data to the clipboard using any method found

-osc52
: push data to the clipboard specifically using xterm's osc52 escape sequence

-totp
: generate a totp code from the data

-K
: ignore any keys stored in the system keyring, prompt for a fresh password and then update the keyring with that

-csv
: export key-value pairs to a csv file

-xml
: export key-value pairs to a xml file

-json
: export key-value pairs to a json file

-zcsv
: export key-value pairs to a pkzip encrypted csv file

-zxml
: export key-value pairs to a pkzip encrypted xml file

-zjson
: export key-value pairs to a pkzip encrypted json file

-7zcsv
: export key-value pairs to a pkzip encrypted csv file

-7zxml
: export key-value pairs to a pkzip encrypted xml file

-7zjson
: export key-value pairs to a pkzip encrypted json file

-scsv
: export key-value pairs to a openssl encrypted csv file

-sxml
: export key-value pairs to a openssl encrypted xml file

-sjson
: export key-value pairs to a openssl encrypted json file

-debug
: output debugging. N.B. THIS WILL INCLUDE LOCKBOX PASSWORDS.

-version
: show program version

--version
: show program version

-help
: show program help

--help
: show program help

-?
: show program help



SETTINGS
========

the 'show-config' and 'config-set' commands allow manipulation of a number of application settings that are stored in `~/.config/treasury/treasury.conf`. 

At current these settings are:


```
algo                aes-256-cbc
clip_cmd            xsel -i -p -b,xclip -selection clipboard,pbcopy
digest              sha256
edit_cmd            vim,vi,pico,nano
iview_cmd           imlib2_view,fim,feh,display,xv,phototonic,qimageviewer,pix,sxiv,qimgv,qview,nomacs,geeqie,ristretto,mirage,fotowall,links -g
keyring             y
keyring_timeout     3600
mlock               n
pass_hide           stars+1
qr_cmd              qrencode -o
resist_strace       n
scrub_files         n
sync_in             ~/.treasury/sync_in/
sync_out            ~/.treasury/sync_out/
syslog              y

```


clip_cmd
: a comma separated list of commands that can be used to set the system clipboard. It is assumed these commands take input on stdin. treasury.lua will use the first application in this list that it finds installed on the system.

iview_cmd
: a comma separated list of image viewer commands to use when displaying qr codes.

edit_cmd
: a comma separated list of text editor commands to use when editing large secrets.

syslog 
: should messages should be sent to the system log when an incorrect password is entered when someone attempts to access a lockbox. Values are 'y' and 'n' for yes and no.

digest 
: which hashing function openssl uses for key expansion in encryption. You should not change this unless you really know what you're doing.

algo
: which encryption method openssl uses. You should not change this unless you really know what you're doing.

coredumps
: whether treasury.lua should prevent itself producing coredumps should it crash for any reason. This is set to 'y' by default.

mlock
: whether treasury.lua should attempt to lock itself in memory. If you set this to 'y' then you must ensure that treasury.lua is allowed to lock enough pages of memory to hold all it's code and data. This is a security feature intended to prevent data being swapped out to disk, but it is somewhat experiemental.

resist_strace
: disallow stracing of the app. It will exit if it is already being straced. There is a race condition here where a skilled attacker could alter treasury.lua's behavior to allow stracing, which is why this is called 'resist' rather than 'deny'. By default this is off ('n').

scrub_files 
: overwrite deleted files with random data. This was once held to be vital to prevent data recovery, however in the modern age we have complex filesystems that may well keep backups of the original data, and we have SSD drives, which suffer 'write wearing' meaning that repeated writes gradually wear them out, so this feature is not considered important anymore. Defaults to 'off' ('n').

keyring
: whether to use the linux keyring system. This requires keyutils/keyctl to be installed. When this boolen option is turned on ('y') it will store passwords in the kernel keyring system as they are typed in. After being stored, treasury.lua will not need to ask for the password going forwards, and will 'remember' it for that user, until that user logs out. treasury.lua will first try to store keys in the 'session' keyring, and if there isn't a session keyring, it will fall back to the  'user' keyring. The user keyring carries some dangers that anyone logged in as the user can get the password from the user keyring, even if they have a different login session. This feature is new and experimental, so it defaults to off ('n'). 

keyring_timeout
: specify a timeout in seconds for passwords stored in the kernel keyring. If a given password is unused for longer than this time, then it will be deleted from the keyring. The default is one hour (3600 seconds).

sync_in
: directory to search for 'sync' files to update lockboxes from ~/.treasury/sync_in/

sync_out
: directory to export 'sync' files to  ~/.treasury/sync_out/


Import/Export
=============

treasury.lua can import data from files in csv, xml and json format. Each of these file formats and also be wrapped with zip, 7zip, or openssl encryption. The purpose of these wrappers is to provide a means of moving data between systems in an encrypted format, even if it's the relatively weak encryption of pkzip/info-zip.

For CSV files the default format is: 

```
key, value, notes, updated time
```

For XML files the default format is:

```
<item>
<name>key</name>
<value>value</value>
<notes>extra notes</notes>
<updated>updated timestamp</updated>
</item>

```

for JSON files the default format is:

```
{
"name": key,
"value": value,
"notes": extra notes,
"updated": updated timestamp,
}
```


When using PKZIP or INFOZIP as a wrapper the data must be extracted using the '-p' command-line option, as the data was read from stdin and info-zip (somewhat stupidly) stores this as a file called '-'. Thus, to extract the data to a file you should use:

```
unzip -p secrets.zcsv > secrets.csv.
```
 
When using 7zip data can be extracted to a file using:

```
7za x <file>
```

or to stdout using 

```
7za x -so <file>
```


Note that when extracting to stdout 7zip will not prompt for password, but does expect a password to be typed in.


When using OPENSSL as a wrapper the unpack command has the format `openssl enc -d -a -md <digest algo> -<encryption algo> -pbkdf2 in <file>` where 'digest algo' and 'encryption algo' are the algorithms specified in settings as 'digest' and 'also' respectively. e.g.:

```
openssl enc -d -a -md sha256 -aes-256-cbc -pbkdf2 -in secrets.scsv
```


The type of file to export to is specified by the appropriate command-line options. If none of these are present, treasury will try to guess the file-type from it's extension. For encrypted files the extensions have the forms `.zcsv` `.7zcsv` or `.scsv` etc.



## Syncing

treasury.lua has a simple syncing system. When changes are made to a lockbox that lockbox is copied to a 'sync_out' directory (default '~/.treasury/sync_out' ). Whenever a lockbox is opened, treasury.lua checks a 'sync_in' directory (default ~/.treasury/sync_in) for any files that it should import to update the lockbox. This means that, if files are pushed from sync_out using rsync or some kind of FTP system, to a common storage server, and if they are regularly synced from that server to sync_in, then multiple instances of treasury.lua can stay in sync by this means. Syncing adds or overwrites entries, but never deletes them if they are missing in the imported sync file. Unfortunately entries that are outright deleted have to be deleted on all systems manually.

Each file dropped in 'sync_out' have the hostname included in their filename, thus ensuring that different systems should not overwrite each other's files. As the files are themselves copies of lockboxes, they are encrypted as the lockboxes are. Export to 'sync_out' does not require decrypting the files, so no passwords are asked for, and the process can be run automated or on a schedule out of cron.

Files can be copied from a common server into the 'sync_in' directroy. When a request is made to lookup a value from a lockbox, treasury.lua will check for any imports from 'sync_in' first, so that it looks u from an up-to-date version of the file. treasury.lua tries to ask for passwords only once, and thus will ask for the password for the destination lockbox, and try using that to open the 'sync' files. If this fails it will then ask for the password of any sync file that doesn't work with the destination lockboxes password. For this reason it's likely a good idea to use the same lockbox passwords on all systems that will be synched, otherwise the burden of typing in passwords for different systems can become oppressive.

Alternatively syncing can be controlled more manually using the 'sync' and 'send' command-line options of treasury.lua. The 'send' command is used to just send a lockbox, or lockboxes to the specified destination. It will do this regardless of whether those lockboxes have changed. 'send' does this without decrypting the lockboxes, and thus does not have to ask the user for a password, making it suitable for automated or scheduled use. When producing output files, 'send' includes the hostname of the system in the resulting file so that sync files from multiple hosts can share the same directory on a central server, allowing these hosts to all sync from the same central authority. 'send' has two possible usages:


### Send a specific lockbox

```
treasury.lua send <box path> <destination>
```

in the above use case the box at <box path> is sent to directory "<destination>". The use of the box file path, rather than the box name, allows sending lockbox files that aren't in the usual working directory of treasury. Since treasury v1.14 the <destination> part of a send command can be an ssh: url.



### Send all known lockboxes

```
treasury.lua send <destination>
```

in the above use case all lockboxes "known" to treasury (that is found in the standard treasury working directory) are sent to "<destination>". The use of the box file path, rather than the box name, allows sending lockbox files that aren't in the usual working directory of treasury. Since treasury v1.14 the <destination> part of a send command can be an ssh: url.

There are two commands relating to importing sync files:

* The "update" command is driven from known lockboxes. For each lockbox in the working directory it searches for matching sync files in the 'sync_in' directory and imports them. The update command takes no arguments.

* The "sync" command is driven from "sync files". It searches for such files in a path, and imports imports them, creating new lockboxes if needed. The sync command accepts arguments that are paths to sync files. If no such path is given it will search for files in the "sync_in" directory. The "sync" command can accept ssh: urls as input file paths.


### Examples

update all existing lockboxes:

```
treasury.lua update
```


sync from all/any files found in 'sync_in' directory, creating lockboxes if they don't already exist

```
treasury.lua sync
```


sync from files found at paths

```
treasury.lua sync /var/sync_in/*.sync /home/sync/treasury/*.sync
```


sync from files on an ssh server

```
treasury.lua sync ssh:myserver/sync/treasury/*.sync
```



TOTP
====

TOTP is a system that generates an authentication code from the combination of a shared, secret key and the current time. To generate TOTP codes with treasury.lua you must first store the secret key as you would any other secret, probably using 'site name' as the key:

```
 treasury.lua add sites_totp mysite KS1AAEHGB42KD9NCP
```

Then a TOTP code can be generated from the secret key using:

```
 treasury.lua get sites_totp mysite -totp
```

The "-totp" option to the 'get' command will calculate a TOTP code from the stored value, and display that instead of the stored value itself. This requires the stored value to be a base32 encoded secret. The TOTP calculation is google-compatible (6 digits, period 30 seconds).


Attacks and Vulnerabilities
===========================

treasury.lua passes data in plaintext to the openssl command in order to have it encrypted, and receives it from the openssl command when it is decypted. This means that anyone who can attach an strace to treasury.lua could see this data. If the 'resist_strace' setting is turned on, then this becomes more difficult to achieve, but as strace and other such tools can be used to change the code of a running program, the possibility exists to disable the 'resist_strace' feature. However, anyone who had the ability to strace treasury.lua likely has the ability to modify it's program code on disk, or install a keylogger and obtain the password, or any number of other attacks. 

The other major vulnerability of treasury.lua is leaving sensitive data around on the disk. treasury.lua generally holds decrypted data in memory, but there are two or three ways it could get transferred to disk:

Coredumps
---------

As a coredump is a dump of the programs code and data, it can contain decrypted secrets. The 'coredumps' setting should be set on ('y') to prevent the production of coredumps.

Swapping
--------

If swap partitions or swap files are being used to provide virtual memory, then the code and data of treasury.lua can get swapped out to disk. The 'mlock' option, if turned on, should prevent this, but issues can then arise with OS level limits on the number of locked pages. Alternately consider if you really need a swap partition on a modern machine, with all the memory modern machines tend to have. Perhaps it's worth running treasury.lua on a lightweight machine (e.g. a Raspberry Pi) without swap and accessing it over an encrypted channel (e.g. ssh) to obtain secrets?

Plaintext import or export files
--------------------------------

If secrets are imported from plaintext files, or exported to plaintext files, then the data of those files can be left on disk. In the case of plaintext files, you can turn on 'scrub_files', and treasury.lua will attempt to overwrite the files with random data after importing them. HOWEVER, you should not do this on an SSD drive, as these drives will only support so many write operations per sector. Furthermore you should be aware that modern filesystems do a lot of magic in the background, and so might keep a backup of a file, or might decide that instead of overwriting the existing data it is more efficent to create a new file, leaving the old data still on the drive.

Root can access keyring
-----------------------

If the keyring feature is used, then the root user will be able to switch users, or log in as other users, and read their encrypted files. However, the root user is so powerful that they can attack users in any number of ways, using keyloggers, changing the treasury.lua program, etc, etc. Keyring access might make it easier, but even with the keyring feature turned off they can still monitor the input/activity of users. You should never unpack encrypted files on systems you don't own. 
