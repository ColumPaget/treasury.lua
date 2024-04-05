PREFIX=/usr/local

all:
	cat includes.lua config.lua findcmd.lua filetype.lua file_scrub.lua expect.lua editor.lua qr_code.lua clipboard.lua keyring.lua sync.lua hosts.lua openssl.lua ui.lua lockbox.lua lockboxes.lua import.lua import_csv.lua import_json.lua import_xml.lua export.lua command_line.lua output.lua shell.lua help.lua main.lua > treasury.lua
	chmod a+x treasury.lua

check:
	./check.sh

install:
	-mkdir -p $(PREFIX)/bin
	cp -f treasury.lua $(PREFIX)/bin
	-mkdir -p $(PREFIX)/share/man/man1
	cp -f treasury.lua.1 $(PREFIX)/share/man/man1


user_install:
	-mkdir -p ~/bin
	cp -f treasury.lua ~/bin
	-mkdir -p ~/.local/share/man/man1
	cp treasury.lua.1 ~/.local/share/man/man1
	
