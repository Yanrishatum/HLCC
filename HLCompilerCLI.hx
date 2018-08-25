
import haxe.io.Path;
import sys.FileSystem;

class HLCompilerCLI
{
  #if hlc
  private static inline var COMMAND:String = "hlcc";
  #else
  private static inline var COMMAND:String = "hl hlcc.hl";
  #end
  private static inline var VERSION:String = "1.0.0";
  
  private static var options:Array<CliOption>;
  private static var compiler:HLCompiler;
  private static var arg:Array<String>;
  
  public static function main()
  {
    HLCompiler.error = handleError;
    compiler = new HLCompiler();
    
    HLCompiler.setup();
    
    options = [
      { short: "-h", long: "--help", argnum: 0, callback: printHelp, argdescr: "", descr: "Print this text" },
      { short: "-v", long: "--verbose", argnum: 0, callback: () -> compiler.verbose = true, argdescr: "", descr: "Verbose output" },
      { short: "-d", long: "--dll", argnum: 0, callback: () -> compiler.copyDll = true, argdescr: "", descr: "Copy DLL files on which resulting executable depends." },
      { short: "-x", long: "--hxml", argnum: 1, callback: setHxml, argdescr: "<hxml path>", descr: "Compile from HXML" },
      { short: "-j", long: "--json", argnum: 1, callback: setJson, argdescr: "<hlc.json path>", descr: "Compile from hlc.json" },
      // { short: "-", long: "", argnum: 1, callback: , argdescr: "", descr: "" },
      // { short: "", long: "", argnum: 1, callback: , argdescr: "", descr: "" },
      // { short: "", long: "", argnum: 1, callback: , argdescr: "", descr: "" },
      // { short: "", long: "", argnum: 1, callback: , argdescr: "", descr: "" },
      // { short: "", long: "", argnum: 1, callback: , argdescr: "", descr: "" },
      // { short: "", long: "", argnum: 1, callback: , argdescr: "", descr: "" },
    ];
    
    var args:Array<String> = Sys.args();
    
    if (args.length == 0) printHelp();
    for (opt in options)
    {
      var index:Int = args.indexOf(opt.short);
      if (index == -1) index = args.indexOf(opt.long);
      if (index != -1)
      {
        if (index + opt.argnum >= args.length)
        {
          handleError("Not enough arguments for " + opt.long);
        }
        arg = new Array();
        for (i in 0...opt.argnum)
        {
          arg.push(args[i + index + 1]);
        }
        opt.callback();
      }
    }
    var path:String = args[args.length - 1];
    if (FileSystem.exists(path))
    {
      if (FileSystem.isDirectory(path))
      {
        var test:String = Path.join([path, "hlc.json"]);
        if (FileSystem.exists(test))
        {
          compiler.compileJson(test);
          Sys.exit(0);
        }
        
        for (file in ["build_hlc.hxml", "build_c.hxml", "build.hxml"])
        {
          test = Path.join([path, file]);
          if (FileSystem.exists(test))
          {
            // compiler.compileHxml(test);
            // Sys.exit(0);
            handleError("Found HXML, but HXML parsing not yet supported");
          }
        }
      }
      else
      {
        var p:Path = new Path(path);
        if (p.ext == "json")
        {
          compiler.compileJson(path);
          Sys.exit(0);
        }
        if (p.ext == "hxml")
        {
          handleError("Found HXML, but HXML parsing not yet supported");
        }
      }
    }
  }
  
  private static function handleError(msg:String):Void
  {
    Sys.println(msg);
    Sys.exit(1);
  }
  
  private static function setHxml():Void
  {
    handleError("HXML not yet supported");
  }
  
  private static function setJson():Void
  {
    compiler.compileJson(arg[0]);
    Sys.exit(0);
  }
  
  private static function printHelp():Void
  {
    var size:Array<Int> = [0, 0, 0, 0];
    var table:Array<Array<String>> = new Array();
    for (opt in options)
    {
      table.push([opt.short, opt.long, opt.argdescr, opt.descr]);
      if (size[0] < opt.short.length) size[0] = opt.short.length;
      if (size[1] < opt.long.length) size[1] = opt.long.length;
      if (size[2] < opt.argdescr.length) size[2] = opt.argdescr.length;
      if (size[3] < opt.descr.length) size[3] = opt.descr.length;
    }
    Sys.println(COMMAND + " [options]\nHLC Compiler v" + VERSION + "\nOptions:");
    for (t in table)
    {
      Sys.println(
        StringTools.lpad(t[0], ' ', size[0]) + ' | ' +
        StringTools.rpad(t[1], ' ', size[1]) + ' | ' +
        StringTools.rpad(t[2], ' ', size[2]) + ' | ' +
        StringTools.rpad(t[3], ' ', size[3])
      );
    }
    Sys.exit(0);
  }
  
}

@:structInit
class CliOption
{
  public var short:String;
  public var long:String;
  public var argnum:Int;
  public var callback:Void->Void;
  public var descr:String;
  public var argdescr:String;
}
