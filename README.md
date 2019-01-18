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

## Downloads
* MS Visual Studio 10 - http://download.microsoft.com/download/1/D/9/1D9A6C0E-FC89-43EE-9658-B9F0E3A76983/vc_web.exe
* hxml_parser - Run:  `haxelib git hxml_parser https://github.com/Yanrishatum/hxml`

## Usage
`hlcc [options]`  
`hlcc -h` for available options  
Doing `hlcc [options] <path-to-hlc.json>` should also work

### A bit more detailed
#### HXML-based
* Make sure your hxml file contains generation of C source with `-hl path/to/sources.c`
* Run `hlcc your-hxml-file.hxml` to compile app.
#### Json-based
* Compile your application into C sources
* Navigate to output folder.
* Run `hlcc hlc.json`


## Current status
* Windows only
* Probably does not work with HXML
* Configuration is kinda icky.
* Generates and calls temporary batch files.
* No input/output fine-tuning
* Tested only on Hashlink 1.6, generated hlc.json version 4000

# License
This work is realeased under public domain.
