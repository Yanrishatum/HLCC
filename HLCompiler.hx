import sys.io.FileOutput;
import sys.io.FileInput;
import sys.io.Process;
import sys.io.File;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import hxml.Hxml;

/*
  -v  | --verbose |           | Verbose output
  -x  | --hxml    | <path>    | Use HXML file to determine required flags (overrides predecessing -i, -o, -m)
  -i  | --input   | <path>    | Set C sources path (defaults to '.', should contain hlc.json file)
  -o  | --output  | <exe>     | Set output executable or folder (defaults to 'main.exe')
  -m  | --main    | <file>    | Set main class file (defaults to 'main.c')
  -d  | --dll     |           | Set this flag to copy hdll files near executable.*/
class HLCompiler
{
  
  #if hlc
  private static inline var COMMAND:String = "compiler_hlc";
  #else
  private static inline var COMMAND:String = "hl compiler_hlc.hl";
  #end
  
  public static var hashlinkBin:String;
  public static var hashlinkInclude:String;
  public static var vcvarsPath:String;
  
  public static dynamic function error(message:String):Void
  {
    throw  message;
  }
  
  public static dynamic function log(message:String):Void
  {
    Sys.println(message);
  }
  
  public static function setup():Void
  {
    inline function where(file:String):String
    {
      var proc:Process = new Process("where", [file]);
      var p:String = proc.stdout.readAll().toString();
      if (proc.exitCode() == 1) return null;
      return StringTools.rtrim(p);
    }
    
    // var env:Map<String, String> = Sys.environment(); // HLC crash
    var errors:Array<String> = new Array();
    
    hashlinkInclude = Sys.getEnv("HASHLINK");
    hashlinkBin = Sys.getEnv("HASHLINK_BIN");
    
    var hl:String = where("hl.exe");
    if (hashlinkBin == null)
    {
      if (hl != null) hashlinkBin = Path.directory(hl);
      else errors.push("No HASHLINK_BIN environment variable found nor hl.exe available in PATH! Hint: Set it to hashlink lib/hdll location");
    }
    if (hashlinkInclude == null)
    {
      if (hashlinkBin != null && FileSystem.exists(hashlinkBin + "/include")) hashlinkInclude = hashlinkBin + "/include";
      else errors.push("No HASHLINK environment variable set and HASHLINK_BIN/hl.exe not available! Hint: Set it to hashlink include folder");
    }
    
    var whereCheck:String = where("vcvarsall.bat");
    if (whereCheck == null)
    {
      inline function vcFind(path:String):Bool
      {
        if (Sys.getEnv(path) != null)
        {
          path = Path.join([Sys.getEnv(path), "../../VC/vcvarsall.bat"]);
          if (FileSystem.exists(path))
          {
            vcvarsPath = path;
            return true;
          }
          else return false;
        }
        return false;
      }
      if (!vcFind("VS100COMNTOOLS") && !vcFind("VS110COMNTOOLS") && !vcFind("VS120COMNTOOLS") && !vcFind("VS140COMNTOOLS"))
      {
        errors.push("vcvarsall.bat not found! Hint: Make it available in path or have a VS1XXCOMNTOOLS (100/110/120/140) environment variable set properly.");
      }
    }
    else vcvarsPath = whereCheck;
    
    if (errors.length > 0)
    {
      error(errors.join("\n"));
    }
  }
  
  public var dlls:Array<String>;
  public var libs:Array<String>;
  public var verbose:Bool;
  public var copyDll:Bool;
  
  public var srcPath:String;
  public var mainName:String;
  public var output:String;
  public var exeName:String;
  
  public function new()
  {
    if (hashlinkBin == null) setup();
    
    libs = [];
    dlls = [];
    
    var hxmlPath:String = null;
    /*
    while (!ArgReader.empty())
    {
      switch(ArgReader.shift())
      {
        case "-h", "--help": printHelp(0);
        case "-v", "--verbose": verbose = true;
        case "-x", "--hxml":
          var path:String = ArgReader.shift();
          var found:Hxml = null;
          if (!FileSystem.exists(path))
          {
            path = Path.withoutExtension(path) + ".hxml";
          }
          if (!FileSystem.exists(path))
          {
            err("HXML file does not exists!");
          }
          hxmlPath = path;
          var base:Hxml = Hxml.parseFile(path);
          base.resolveIncludes(Path.directory(path));
          base.resolveLibraries();
          for(x in base.generateTargetHxmls())
          {
            var targets = x.getTargets();
            for(t in targets)
            {
              if (t.target.indexOf("-hl") != -1 && StringTools.endsWith(t.path, ".c"))
              {
                found = x;
                srcPath = Path.directory(t.path);
                mainName = Path.withoutDirectory(t.path);
                output = Path.directory(t.path);
                exeName = Path.withoutDirectory(Path.withExtension(t.path, "exe"));
                break;
              }
            }
            if (found != null) break;
          }
          if (found == null)
          {
            err("Hxml file does not generate HL C code!");
          }
          
        case "-i", "--input":
          var path:String = ArgReader.shift();
          if (!FileSystem.exists(path)) err("Input path does not exists!");
          if (Path.extension(path) == "c")
          {
            mainName = Path.withoutDirectory(path);
            srcPath = Path.directory(path);
          }
          else 
          {
            srcPath = path;
          }
        case "-o", "--output":
          var path:String = ArgReader.shift();
          if (Path.extension(path) == "exe")
          {
            output = Path.directory(path);
            exeName = Path.withoutDirectory(path);
          }
          else 
          {
            output = path;
          }
        case "-m", "--main":
          mainName = ArgReader.shift();
          if (Path.extension(mainName) != "c") mainName = Path.withExtension(mainName, "c");
        case "-d", "--dll":
          copyDll = true;
        default:
          err("Unrecognized argument: " + ArgReader.prev());
          printHelp(0);
      }
    }
    
    if (srcPath == null)
    {
      err("No source path provided");
    }
    
    var hlcJsonPath = Path.join([srcPath, "hlc.json"]);
    if (hxmlPath != null && !FileSystem.exists(hlcJsonPath))
    {
      Sys.command("haxe", [hxmlPath]);
    }
    if (!FileSystem.exists(hlcJsonPath))
    {
      err("Can't find hlc.json file!");
    }
    if (verbose) Sys.println("Reading hlc.json...");
    readHlcJson(hlcJsonPath);
    
    var args:Array<String> = ["/Ox", "/Fo" + Path.join([output, Path.withoutExtension(exeName)]), "/Fe" + Path.join([output, exeName]), "-I", '"' + hashlinkInclude + '"', "-I", '"' + srcPath + '"', '"' + Path.join([srcPath, mainName]) + '"'];
    for (lib in libs)
    {
      args.push("\"" + Path.join([hashlinkBin, lib]) + "\"");
    }
    if (verbose)
    {
      Sys.println("Compiling...");
      if (vcvarsPath != null) Sys.println(vcvarsPath);
      Sys.println("cl " + args.join(" ") + "\n");
    }
    
    var temp:String = Sys.getEnv("TEMP") + "/_hlc_" + randomName() + ".tmp.bat";
    var fio = File.write(temp);
    fio.writeString("@echo off \n");
    if (vcvarsPath != null) fio.writeString("call \"" + vcvarsPath + "\"\n");
    fio.writeString("cl.exe " + args.join(" "));
    fio.close();
    var result:Int = Sys.command(temp);
    FileSystem.deleteFile(temp);
    
    if (result == 0)
    {
      if (copyDll)
      {
        if (verbose) Sys.print("Copying dlls... ");
        var first:Bool = true;
        for (dll in dlls)
        {
          var proc:Process = new Process("cmd", ["/Q", "/C", "copy", "/Y", StringTools.replace(Path.join([hashlinkBin, dll]), "/", "\\"), StringTools.replace(Path.join([output, dll]), "/", "\\")]);
          proc.exitCode();
          if (verbose)
          {
            if (!first)
            {
              Sys.print(", ");
            }
            else first = false;
            Sys.print(dll);
          }
        }
        if (verbose) Sys.print("\n");
      }
    }
    else if (verbose) Sys.println("Compilation failed with exit code: " + result);
    */
  }
  
  public function compileJson(path:String):Void
  {
    var json:HLCJson;
    try 
    {
      if (verbose) log("Reading hlc.json at path: " + path);
      json = Json.parse(sys.io.File.getContent(path));
    }
    catch(e:Dynamic)
    {
      error("Could not parse json with error: " + e);
      return;
    }
    if (Std.int(json.version / 1000) != 4)
    {
      error("Only hlc.json version 4XXX supported!");
      return;
    }
    if (verbose) log("Reading libraries...");
    
    for (lib in json.libs)
    {
      switch(lib)
      {
        case "std":
          libs.push("libhl.lib");
          dlls.push("libhl.dll");
          if (verbose) log("Added library: libhl.lib | Dlls: libhl.dll");
        case "openal":
          libs.push("openal.lib");
          dlls.push("openal.hdll");
          dlls.push("OpenAL32.dll");
          if (verbose) log("Added library: openal.lib | Dlls: openal.hdll, OpenAL32.dll");
        case "sdl":
          libs.push("sdl.lib");
          dlls.push("sdl.hdll");
          dlls.push("SDL2.dll");
          if (verbose) log("Added library: sdl.lib | Dlls: sdl.hdll, SDL2.dll");
        default: // directx, fmt, sqlite, ui, uv, ssl
          if (FileSystem.exists(hashlinkBin + "/" + lib + ".lib"))
          {
            libs.push(lib + ".lib");
            if (verbose) log("Added library: " + lib + ".lib");
          }
          else if (verbose) log("Could not locate library: " + lib);
          if (FileSystem.exists(hashlinkBin + "/" + lib + ".hdll"))
          {
            dlls.push(lib + ".hdll");
            if (verbose) log("Added dll: " + lib + ".hdll");
          }
          if (FileSystem.exists(hashlinkBin + "/" + lib + ".dll"))
          {
            dlls.push(lib + ".dll");
            if (verbose) log("Added dll: " + lib + ".dll");
          }
      }
    }
    srcPath = Path.directory(path);
    if (srcPath == "") srcPath = ".";
    mainName = json.files[0];
    output = srcPath;
    exeName = Path.withExtension(mainName, "exe");
    if (verbose)
    {
      log('Source path: $srcPath\nMain .c file: $mainName\nobj/exe output path: $output\nExecutable name: $exeName');
    }
    compile();
  }
  
  public function compileHxml(path:String):Void
  {
    var base:Hxml = null;
    try 
    {
      base = Hxml.parseFile(Path.withExtension(path, "hxml"));
    }
    catch (e:Dynamic)
    {
      error("Could not parse HXML file with error: " + e);
      return;
    }
    var hxmlPath:String = path;
    base.resolveIncludes(Path.directory(path));
    base.resolveLibraries();
    for(x in base.generateTargetHxmls())
    {
      var targets = x.getTargets();
      for(t in targets)
      {
        if (t.target.indexOf("-hl") != -1 && StringTools.endsWith(t.path, ".c"))
        {
          Sys.command("haxe", [hxmlPath]);
          compileJson(Path.join([Path.directory(t.path), "hlc.json"]));
          return;
        }
      }
    }
    
    error("Hxml file does not generate HL C code!");
  }
  
  public function compile():Void
  {
    inline function checkExists(path:String):Bool
    {
      return path != null && FileSystem.exists(path);
    }
    if (!checkExists(srcPath))
    {
      error("Source path not set or does not exists!");
      return;
    }
    var mainPath:String = Path.join([srcPath, mainName]);
    if (!checkExists(mainPath))
    {
      error("Entry point not set or does not exists!");
      return;
    }
    if (output == null) output = srcPath;
    if (exeName == null) exeName = Path.withExtension(mainName, "exe");
    var args:Array<String> = [
      "/Ox",
      "/Fo" + Path.join([output, Path.withoutExtension(exeName)]),
      "/Fe" + Path.join([output, exeName]),
      "-I", '"$hashlinkInclude"',
      "-I", '"$srcPath"',
      '"$mainPath"'
    ];
    
    for (lib in libs)
    {
      args.push("\"" + Path.join([hashlinkBin, lib]) + "\"");
    }
    if (verbose)
    {
      log("Compiling...");
      log(vcvarsPath);
      log("cl " + args.join(" ") + "\n");
    }
    
    var temp:String = Sys.getEnv("TEMP") + "/_hlc_" + randomName() + ".tmp.bat";
    var fio = File.write(temp);
    fio.writeString("@echo off \n");
    fio.writeString("call \"" + vcvarsPath + "\"\n");
    fio.writeString("cl.exe " + args.join(" "));
    fio.close();
    var result:Int = Sys.command(temp);
    FileSystem.deleteFile(temp);
    
    if (result == 0)
    {
      if (copyDll)
      {
        if (verbose) Sys.print("Copying dlls... ");
        var first:Bool = true;
        for (dll in dlls)
        {
          File.copy(Path.join([hashlinkBin, dll]), Path.join([output, dll]));
          if (verbose)
          {
            if (!first)
            {
              Sys.print(", ");
            }
            else first = false;
            Sys.print(dll);
          }
        }
        if (verbose) Sys.print("\n");
      }
    }
    else if (verbose) Sys.println("Compilation failed with exit code: " + result);
  }
  
  private function randomName():String
  {
    var buf:StringBuf = new StringBuf();
    for (i in 0...6)
    {
      if (Math.random() > 0.2)
      {
        buf.add(Std.int(Math.random() * 26) + (Math.random() > .5 ? 65 : 97));
        
      }
      else buf.add(Std.int(Math.random() * 10) + 48);
    }
    return buf.toString();
  }
  
}

typedef HLCJson =
{
  var version:Int;
  var libs:Array<String>;
  var defines:Dynamic;
  var files:Array<String>;
}