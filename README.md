## treasury.lua - Another simple secrets keeper app, written in lua

author: Colum Paget (colums.projects@gmail.com)  
licence: GPLv3  

treasury.lua is a simple command-line app for storing short secrets, phone numbers, contact details, passwords, whatever. It uses the openssl command-line app to encrypt data, which is then stored in 'lockboxes' (which are single files containing all items related to a given task or data type). Each lockbox is password-protected, and has an optional password hint that it will display when querying for it's password.


## Requirements
To use treasury you will need to have the following installed:

lua              http://www.lua.org                          at least version 5.3  
libUseful        http://github.com/ColumPaget/libUseful      at least verson 5.0
libUseful-lua    http://github.com/ColumPaget/libUseful-lua  at least version 3.0  

you will need swig (http://www.swig.org) installed to compile libUseful-lua

if you want to use qr-code output, the utility qrencode will need to be installed.



## Build/install

the distribution comes as a load of .lua files that are compiled into a single 'treasury.lua' file using 'make'. A premade 'treasury.lua' is provided. You can copy this to anywhere in your path and run it with lua (`lua <path>`, e.g `lua /usr/local/bin`), or else use linux's 'binfmt' system to invoke lua for lua scripts.


`make check` runs various checks that features are working. You don't normally need to run this.
`make install` copies treasury.lua to /usr/local/bin, you can change the prefix with, for example, `make install PREFIX=/usr`
`make user_install` copies treasury.lua to ~/bin ('bin' under the user's home directory)


## Usage


```
usage: lua treasury.lua [action] [lockbox] [key] [value]

actions:
   new [lockbox]                           create a new lockbox
   list [lockbox]                          list keys in a lockbox
   dump [lockbox]                          dump lockbox in plain text
   add [lockbox] [key] [value]             add a key/value pair to a lockbox
   add [lockbox] [key] -g                  generate a 32bit random string, and add it to a lockbox
   add [lockbox] [key] -generate           generate a 32bit random string, and add it to a lockbox
   add [lockbox] [key] -glen <len>         generate a random string, and add it to a lockbox
   del [lockbox] [key]                     remove a key/value pair from a lockbox
   rm  [lockbox] [key]                     remove a key/value pair from a lockbox
   get [lockbox] [key]                     get the value matching 'key' in a lockbox
   get [lockbox] [key] -o <path>           get the value matching 'key' in a lockbox, and write it to <path>
   get [lockbox] [key] -qr                 get the value matching 'key' in a lockbox, and display as qr code
   get [lockbox] [key] -qr -o <path>       get the value matching 'key' in a lockbox, and write as a qr code PNG to <path>
   get [lockbox] [key] -clip               get the value matching 'key' in a lockbox, and push it to clipboard
   get [lockbox] [key] -osc52              get the value matching 'key' in a lockbox, and push it to clipboard using xterm's osc52 command
   get [lockbox] [key] -totp               get the value matching 'key' in a lockbox, use it to generate a google-authenticator compatible TOTP code.
   entry [lockbox]                         enter 'data entry' mode for localbox
   shell [lockbox]                         enter 'shell' mode for localbox
   sync [path]                             sync key/value pairs from a lockbox file
   chpw [box]                              change password for a lockbox
   find [lockbox] [search pattern]         find key/value pairs matching 'search pattern'
   sync [path]                             sync key/value pairs from a lockbox file
   import [lockbox] [path]                 import key/value pairs from a file
   export [lockbox] [path]                 export key/value pairs to a file
   export [lockbox] [path] -csv            export key/value pairs from a csv file
   export [lockbox] [path] -xml            export key/value pairs from a xml file
   export [lockbox] [path] -json           export key/value pairs from a json file
   export [lockbox] [path] -zcsv           export key/value pairs from a pkzipped csv file (with password)
   export [lockbox] [path] -zxml           export key/value pairs from a pkzipped xml file (with password)
   export [lockbox] [path] -zjson          export key/value pairs from a pkzipped json file (with password)
   export [lockbox] [path] -7zcsv          export key/value pairs from a 7zipped csv file (with password)
   export [lockbox] [path] -7zxml          export key/value pairs from a 7zipped xml file (with password)
   export [lockbox] [path] -7zjson         export key/value pairs from a 7zipped json file (with password)
   show-config                             print out application config
   config-set [name] [value]               change a config value
   version                                 print program version
   -version                                print program version
   --version                               print program version
   --help                                  print help
   -help                                   print help
   help                                    print help
   -?                                      print help
```



## Settings

the 'show-config' and 'config-set' commands allow manipulation of a number of application settings that are stored in `~/.config/treasury/treasury.conf`. At current these settings are:


```
clip_cmd            xsel -i -p -b,xclip -selection clipboard,pbcopy
iview_cmd           imlib2_view,fim,feh,display,xv,phototonic,qimageviewer,pix,sxiv,qimgv,qview,nomacs,geeqie,ristretto,mirage,fotowall,links -g
edit_cmd            vim,vi,pico,nano
syslog              y
digest              sha256
algo                aes-256-cbc
pass_hide           stars+1
mlock               n
resist_strace       n
scrub_files         n
keyring             n
keyring_timeout     3600
```


The 'clip_cmd' setting is a comma separated list of commands that can be used to set the system clipboard. It is assumed these commands take input on stdin. treasury.lua will use the first application in this list that it finds installed on the system.

The 'iview_cmd' settings is a comma separated list of image viewer commands to use when displaying qr codes.

The 'edit_cmd' settings is a comma separated list of text editor commands to use when editing large secrets.

The 'syslog' setting determines whether messages should be sent to the system log when an incorrect password is entered when someone attempts to access a lockbox. Values are 'y' and 'n' for yes and no.

The 'digest' setting configures which hashing function openssl uses for key expansion in encryption. You should not change this unless you really know what you're doing.

The 'algo' setting configures which encryption method openssl uses. You should not change this unless you really know what you're doing.

The 'coredumps' setting determines whether treasury.lua should prevent itself producing coredumps should it crash for any reason. This is set to 'y' by default.

The 'mlock' setting determines whether treasury.lua should attempt to lock itself in memory. If you set this to 'y' then you must ensure that treasury.lua is allowed to lock enough pages of memory to hold all it's code and data. This is a security feature intended to prevent data being swapped out to disk, but it is somewhat experiemental.

The 'resist_strace' setting configures treasury.lua to disallow stracing of the app. It will exit if it is already being straced. There is a race condition here where a skilled attacker could alter treasury.lua's behavior to allow stracing, which is why this is called 'resist' rather than 'deny'. By default this is off ('n').

The 'scrub_files' feature overwrites deleted files with random data. This was once held to be vital to prevent data recovery, however in the modern age we have complex filesystems that may well keep backups of the original data, and we have SSD drivers, which suffer 'write wearing' meaning that repeated writes gradually wear them out, so this feature is not considered important anymore. Defaults to 'off' ('n').

The 'keyring' feature uses the linux keyring system. This requires keyutils/keyctl to be installed. When this boolen option is turned on ('y') it will store passwords in the kernel keyring system as they are typed in. After being stored, treasury.lua will not need to ask for the password going forwards, and will 'remember' it for that user, until that user logs out. treasury.lua will first try to store keys in the 'session' keyring, and if there isn't a session keyring, it will fall back to the  'user' keyring. The user keyring carries some dangers that anyone logged in as the user can get the password from the user keyring, even if they have a different login session. This feature is new and experimental, so it defaults to off ('n'). 

The 'keyring_timeout' setting allows setting a timeout in seconds for passwords stored in the kernel keyring. If a given password is unused for longer than this time, then it will be deleted from the keyring. The default is one hour (3600 seconds).


## Import/Export

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


When using PKZIP or INFOZIP as a wrapper the data must be extracted using the '-p' command-line option, as the data was read from stdin and info-zip (somewhat stupidly) stores this as a file called '-'. Thus, to extract the data to a file you should use `unzip -p secrets.zcsv > secrets.csv`. 

When using 7zip data can be extracted to a file using `7za x <file>` or to stdout using `7za x -so <file>`. Note that when extracting to stdout 7zip will not prompt for password, but does expect a password to be typed in.

When using OPENSSL as a wrapper the unpack command has the format `openssl enc -d -a -md <digest algo> -<encryption algo> -pbkdf2 in <file>` where 'digest algo' and 'encryption algo' are the algorithms specified in settings as 'digest' and 'also' respectively. e.g.:

```
openssl enc -d -a -md sha256 -aes-256-cbc -pbkdf2 -in secrets.scsv
```


The type of file to export to is specified by the `-csv` `-xml` `-json` `-zcsv` `-zxml` `-zjson` `-7zcsv` `-7zxml` `-7zjson` `-scsv` `-sxml` and `-sjson` command-line options. If none of these are present, treasury will try to guess the fileetype from it's extension. For encrypted files the extentions have the forms `.zcsv` `.7zcsv` or `.scsv` etc.



## Syncing

treasury.lua has a simple syncing system. When changes are made to a lockbox that lockbox is copied to '~/.treasury/sync_out'. Whenever a lockbox is opened, treasury.lua checks in 'sync_in' for any files that it should import to update the lockbox. This means that, if files are pushed from sync_out using rsync or somekind of FTP system, to a common storage server, and if they are regularly synced from that server to sync_in, then multiple instances of treasury.lua can stay in sync by this means. Each file droppend in 'sync_out' has the hostname included, ensuring that different systems should not overwrite each other's files. As the files are themselves copies of lockboxes, they are encrypted as the lockboxes are. However, this does mean that the same password has to be used for the same lockbox on all systems that are synced this way.

## TOTP

The `-totp` option to the 'get' command will calculate a TOTP code from the stored value, and display that instead of the stored value itself. This requires the stored value to be a base32 encoded secret. The TOTP calculation is google-compatible (6 digits, period 30 seconds).


## Attacks and Vulnerabilities

treasury.lua passes data in plaintext to the openssl command in order to have it encrypted, and receives it from the openssl command when it is decypted. This means that anyone who can attach an strace to treasury.lua could see this data. If the 'resist_strace' setting is turned on, then this becomes more difficult to achieve, but as strace and other such tools can be used to change the code of a running program, the possibility exists to disable the 'resist_strace' feature. However, anyone who had the ability to strace treasury.lua likely has the ability to modify it's program code on disk, or install a keylogger and obtain the password, or any number of other attacks. 

The other major vulnerability of treasury.lua is leaving sensitive data around on the disk. treasury.lua generally holds decrypted data in memory, but there are two or three ways it could get transferred to disk:

1) Coredumps
As a coredump is a dump of the programs code and data, it can contain decrypted secrets. The 'coredumps' setting should be set on ('y') to prevent the production of coredumps.

2) Swapping
If swap partitions or swap files are being used to provide virtual memory, then the code and data of treasury.lua can get swapped out to disk. The 'mlock' option, if turned on, should prevent this, but issues can then arise with OS level limits on the number of locked pages. Alternately consider if you really need a swap partition on a modern machine, with all the memory modern machines tend to have. Perhaps it's worth running treasury.lua on a lightweight machine (e.g. a Raspberry Pi) without swap and accessing it over an encrypted channel (e.g. ssh) to obtain secrets?

3) Plaintext import or export files
If secrets are imported from plaintext files, or exported to plaintext files, then the data of those files can be left on disk. In the case of plaintext files, you can turn on 'scrub_files', and treasury.lua will attempt to overwrite the files with random data after importing them. HOWEVER, you should not do this on an SSD drive, as these drives will only support so many write operations per sector. Furthermore you should be aware that modern filesystems do a lot of magic in the background, and so might keep a backup of a file, or might decide that instead of overwriting the existing data it is more efficent to create a new file, leaving the old data still on the drive.

4) Root can access keyring.
If the keyring feature is used, then the root user will be able to switch users, or log in as other users, and read their encrypted files. However, the root user is so powerful that they can attack users in any number of ways, using keyloggers, changing the treasury.lua program, etc, etc. Keyring access might make it easier, but even with the keyring feature turned off they can still monitor the input/activity of users. You should never unpack encrypted files on systems you don't own. 
