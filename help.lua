function PrintHelp()

print("treasury.lua stores key-value pairs in encrypted files called 'lockboxes'\n");
print("usage: lua treasury.lua [action] [lockbox] [key] [value]\n")
print("actions:")
print("   new [lockbox]                           create a new lockbox")
print("   list [lockbox]                          list keys in a lockbox")
print("   dump [lockbox]                          dump lockbox in plain text")
print("   add [lockbox] [key] [value]             add a key/value pair to a lockbox")
print("   add [lockbox] [key] -g                  generate a 32bit random string, and add it to a lockbox")
print("   add [lockbox] [key] -generate           generate a 32bit random string, and add it to a lockbox")
print("   add [lockbox] [key] -glen <len>         generate a random string, and add it to a lockbox")
print("   del [lockbox] [key]                     remove a key/value pair from a lockbox")
print("   rm  [lockbox] [key]                     remove a key/value pair from a lockbox")
print("   get [lockbox] [key]                     get the value matching 'key' in a lockbox")
print("   get [lockbox] [key] -qr                 get the value matching 'key' in a lockbox, and display as qr code")
print("   get [lockbox] [key] -clip               get the value matching 'key' in a lockbox, and push it to clipboard")
print("   get [lockbox] [key] -osc52              get the value matching 'key' in a lockbox, and push it to clipboard using xterm's osc52 command")
print("   entry [lockbox]                         enter 'data entry' mode for localbox")
print("   shell [lockbox]                         enter 'shell' mode for localbox")
print("   sync [path]                             sync key/value pairs from a lockbox file")
print("   chpw [box]                              change password for a lockbox")
print("   find [lockbox] [search pattern]         find key/value pairs matching 'search pattern'")
print("   sync [path]                             sync key/value pairs from a lockbox file")
print("   import [lockbox] [path]                 import key/value pairs from a file")
print("   export [lockbox] [path]                 export key/value pairs to a file")
print("   export [lockbox] [path] -csv            export key/value pairs from a csv file")
print("   export [lockbox] [path] -xml            export key/value pairs from a xml file")
print("   export [lockbox] [path] -json           export key/value pairs from a json file")
print("   export [lockbox] [path] -zcsv           export key/value pairs from a pkzipped csv file (with password)")
print("   export [lockbox] [path] -zxml           export key/value pairs from a pkzipped xml file (with password)")
print("   export [lockbox] [path] -zjson          export key/value pairs from a pkzipped json file (with password)")
print("   export [lockbox] [path] -7zcsv          export key/value pairs from a 7zipped csv file (with password)")
print("   export [lockbox] [path] -7zxml          export key/value pairs from a 7zipped xml file (with password)")
print("   export [lockbox] [path] -7zjson         export key/value pairs from a 7zipped json file (with password)")
print("   show-config                             print out application config")
print("   config-set [name] [value]               change a config value")
print("   --help                                  print help")
print("   -help                                   print help")
print("   help                                    print help")
print("   -?                                      print help")

print("")
print("The type of file for import and export can be set using the -csv, -xml, -json, -zcsv, -zxml, -zjson, -7zcsv, -7zxml, -7zjson, -scsv, -sxml, -sjson options. Without these the import and export commands will try to guess the filetype.")
print("The import command examines the file at [path] and can open csv, xml and json files, including those that have been packaged/encrypted with pkzip/infozip, 7zip, or simply encrypted with openssl.");
print("The export command uses the extension of the supplied filename to guess the filetype. Thus extensions should be in the form .csv, .zcsv, .7zscv .scsv");
end



-- elseif value=="-f" then cmd.fieldlist=args[i+1]; args[i+1]=""
