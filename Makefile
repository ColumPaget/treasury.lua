all:
	cat includes.lua config.lua findcmd.lua filetype.lua file_scrub.lua expect.lua editor.lua qr_code.lua clipboard.lua keyring.lua sync.lua hosts.lua openssl.lua ui.lua lockbox.lua lockboxes.lua import.lua import_csv.lua import_json.lua import_xml.lua export.lua command_line.lua shell.lua help.lua main.lua > treasury.lua
	chmod a+x treasury.lua
