module reggae.options;

import reggae.types;

import std.file: thisExePath;
import std.conv: ConvException;
import std.path: absolutePath, buildPath;
import std.file: exists;


enum BuildLanguage {
    D,
    Python,
    Ruby,
    JavaScript,
    Lua,
}

struct Options {
    Backend backend;
    string projectPath;
    string dflags;
    string ranFromPath;
    string cCompiler;
    string cppCompiler;
    string dCompiler;
    bool noFetch;
    bool help;
    bool perModule;
    bool isDubProject;
    bool oldNinja;
    string[string] userVars;

    Options dup() @safe pure const nothrow {
        return Options(backend,
                       projectPath, dflags, ranFromPath, cCompiler, cppCompiler, dCompiler,
                       noFetch, help, perModule, isDubProject, oldNinja);
    }

    //finished setup
    void finalize() @safe{
        ranFromPath = thisExePath();

        if(!cCompiler)   cCompiler   = "gcc";
        if(!cppCompiler) cppCompiler = "g++";
        if(!dCompiler)   dCompiler   = "dmd";

        isDubProject = _isDubProject;

        if(isDubProject && backend == Backend.tup) {
            throw new Exception("dub integration not supported with the tup backend");
        }
    }

    private bool _isDubProject() @safe nothrow {
        return buildPath(projectPath, "dub.json").exists ||
            buildPath(projectPath, "package.json").exists;
    }

    string reggaeFilePath() @safe const {
        import std.algorithm, std.array, std.exception, std.conv;

        auto langs = [dlangFile, pythonFile, rubyFile].
            filter!exists.
            map!(a => reggaeFileLanguage(a)).
            array;

        enforce(langs.length < 2, text("Reggae builds may only use one language. Found: ",
                                       langs.map!(to!string).join(", ")));

        if(dlangFile.exists) return dlangFile;
        if(pythonFile.exists) return pythonFile;
        if(rubyFile.exists) return rubyFile;
        if(jsFile.exists) return jsFile;
        if(luaFile.exists) return luaFile;

        immutable path = isDubProject ? "" : projectPath;
        return buildPath(path, "reggaefile.d").absolutePath;
    }

    string dlangFile() @safe const pure nothrow {
        return projectBuildFile;
    }

    string pythonFile() @safe const pure nothrow {
        return buildPath(projectPath, "reggaefile.py");
    }

    string rubyFile() @safe const pure nothrow {
        return buildPath(projectPath, "reggaefile.rb");
    }

    string jsFile() @safe const pure nothrow {
        return buildPath(projectPath, "reggaefile.js");
    }

    string luaFile() @safe const pure nothrow {
        return buildPath(projectPath, "reggaefile.lua");
    }

    string projectBuildFile() @safe const pure nothrow {
        return buildPath(projectPath, "reggaefile.d");
    }

    string toString() @safe const pure {
        import std.conv: text;
        import std.traits: isSomeString, isAssociativeArray;

        string repr = "Options(Backend.";

        foreach(member; this.tupleof) {
            static if(isSomeString!(typeof(member)))
                repr ~= `"` ~ text(member) ~ `", `;
            else static if(isAssociativeArray!(typeof(member)))
                {}
            else
                repr ~= text(member, ", ");
        }

        repr ~= ")";
        return repr;
    }

    string[] rerunArgs() @safe pure const {
        import std.conv: to;

        auto args =  [ranFromPath, "-b", backend.to!string, ];

        if(dflags != "") args ~= ["--dflags='" ~ dflags ~ "'"];
        if(oldNinja) args ~= "--old_ninja";
        if(cCompiler != "") args ~=  ["--cc", cCompiler];
        if(cppCompiler != "") args ~=  ["--cxx", cppCompiler];
        if(dCompiler != "") args ~=  ["--dc", dCompiler];

        args ~= projectPath;

        return args;
    }

    bool isScriptBuild() @safe const {
        import reggae.rules.common: getLanguage, Language;
        return getLanguage(reggaeFilePath) != Language.D;
    }

    BuildLanguage reggaeFileLanguage(in string fileName) @safe const {
        import std.algorithm;

        if(fileName.endsWith(".d"))
            return BuildLanguage.D;
        else if(fileName.endsWith(".py"))
            return BuildLanguage.Python;
        else if(fileName.endsWith(".rb"))
            return BuildLanguage.Ruby;
        else if(fileName.endsWith(".js"))
            return BuildLanguage.JavaScript;
        else if(fileName.endsWith(".lua"))
            return BuildLanguage.Lua;
        else throw new Exception("Unknown language for " ~ fileName);
    }

    BuildLanguage reggaeFileLanguage() @safe const {
        return reggaeFileLanguage(reggaeFilePath);
    }

}


//getopt is @system
Options getOptions(string[] args) @trusted {
    import std.getopt;

    Options options;
    try {
        auto helpInfo = getopt(
            args,
            "backend|b", "Backend to use (ninja|make). Mandatory.", &options.backend,
            "dflags", "D compiler flags.", &options.dflags,
            "d", "User-defined variables (e.g. -d myvar=foo).", &options.userVars,
            "dc", "D compiler to use (default dmd).", &options.dCompiler,
            "cc", "C compiler to use (default gcc).", &options.cCompiler,
            "cxx", "C++ compiler to use (default g++).", &options.cppCompiler,
            "nofetch", "Assume dub packages are present (no dub fetch).", &options.noFetch,
            "per_module", "Compile D files per module (default is per package)", &options.perModule,
            "old_ninja", "Generate a Ninja build compatible with older versions of Ninja", &options.oldNinja,
            );

        if(helpInfo.helpWanted) {
            defaultGetoptPrinter("Usage: reggae -b <ninja|make> </path/to/project>",
                                 helpInfo.options);
            options.help = true;
        }

    } catch(ConvException ex) {
        throw new Exception("Unsupported backend, -b must be one of: make|ninja|tup|binary");
    }

    if(args.length > 1) options.projectPath = args[1].absolutePath;
    options.finalize();

    return options;
}
