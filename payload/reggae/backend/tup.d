module reggae.backend.tup;


import reggae.build;
import reggae.range;
import reggae.options;
import std.array;
import std.typecons;

@safe:

struct Tup {
    enum fileName = "Tupfile";

    Build build;
    const(Options) options;

    this(Build build, in string projectPath) {
        import reggae.config: options;
        auto modOptions = options.dup;
        modOptions.projectPath = projectPath;
        this(build, modOptions);
    }

    this(Build build, in Options options) {
        this.build = build;
        this.options = options;
    }

    string output() const pure {
        return lines.join("\n") ~ "\n";
    }

    string[] lines() const pure {

        string[] lines;
        foreach(target; build.range) {
            if(target.getCommandType == CommandType.code)
                throw new Exception("Command type 'code' not supported for tup backend");

            //tup does its own dependency detection, trying to output
            //dependency files actually causes an error, so we request
            //none to be generated
            immutable line = ": " ~
                target.dependencyFilesString(options.projectPath) ~ " |> " ~
                target.shellCommand(options.projectPath, No.dependencies) ~ " |> " ~
                target.outputsInProjectPath(options.projectPath).join(" ");
            lines ~= line;
        }
        return lines;
    }
}
