module reggae.dependencies;

import std.regex;
import std.algorithm: splitter;

/**
 * Given a source file with a D main() function, return
 * The list of D files to compile to link the executable
 * Includes all dependencies, not just source files to
 * compile.
 */
//@trusted because of splitter
string[] dMainDependencies(in string output) @trusted {
    string[] dependencies = dMainDepSrcs(output);
    auto fileReg = ctRegex!`^file +([^\t]+)\t+\((.+)\)$`;
    foreach(line; output.splitter("\n")) {
        auto fileMatch = line.matchFirst(fileReg);
        if(fileMatch) dependencies ~= fileMatch.captures[2];
    }

    return dependencies;
}



/**
 * Given a source file with a D main() function, return
 * The list of D files to compile to link the executable.
 * Only includes source files to compile
 */
//@trusted because of splitter
string[] dMainDepSrcs(in string output) @trusted {
    string[] dependencies;
    auto importReg = ctRegex!`^import +([^\t]+)[\t\s]+\((.+)\)$`;
    auto stdlibReg = ctRegex!`^(std\.|core\.|etc\.|object$)`;
    foreach(line; output.splitter("\n")) {
        auto importMatch = line.matchFirst(importReg);
        if(importMatch) {
            auto stdlibMatch = importMatch.captures[1].matchFirst(stdlibReg);
            if(!stdlibMatch) {
                dependencies ~= importMatch.captures[2];
            }
        }
    }

    return dependencies;
}
