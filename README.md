# HLCC
A Hashlink tool to compile hlc output

## Configuration
* It expect for Haxe and hl.exe to be available from path
* It expects for `%HASHLINK_BIN%` and `%HASHLINK%` to be set to hl.exe location (hdlls) and `include` folder respectively.
* It expects for `vcvarsall.bat` being available from path, or via `%VS100COMNTOOLS%` as `../../VC/vcvarsall.bat` (VS110, 120 and 140 checked as well)
* It assumes windows is modern enough to have a `where` available.

## Compilation
* You need my fork of hxml library to compile the executable, also library name should be `hxml_parser` and not `hxml` because Haxe did not like that name for some reason.
* Hashlink version at least 1.6
* run `haxe build.hxml`
* run `hl hlcc.hl -j bin/hlc.json` to generate .exe file.

## Usage
`hlcc [options]`  
`hlcc -h` for available options  
Doing `hlcc [options] <path-to-hlc.json>` should also work

## Current status
* Windows only
* Probably does not work with HXML
* Configuration is kinda icky.
* Generates and calls temporary batch files.
* No input/output fine-tuning
* Tested only on Hashlink 1.6, generated hlc.json version 4000

# License
This work is realeased under public domain.