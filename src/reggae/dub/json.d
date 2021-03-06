module reggae.dub.json;

import reggae.dub.info;
import reggae.build;
import std.json;
import std.algorithm: map, filter;


DubInfo getDubInfo(string jsonString) @trusted {
    auto json = parseJSON(jsonString);
    auto packages = json.byKey("packages").array;
    return DubInfo(packages.
                   map!(a => DubPackage(a.byKey("name").str,
                                        a.byKey("path").str,
                                        a.getOptional("mainSourceFile"),
                                        a.getOptional("targetFileName"),
                                        a.byKey("dflags").jsonValueToStrings,
                                        a.byKey("importPaths").jsonValueToStrings,
                                        a.byKey("stringImportPaths").jsonValueToStrings,
                                        a.byKey("files").jsonValueToFiles,
                                        a.getOptional("targetType"),
                                        a.getOptionalList("versions"),
                                        a.getOptionalList("dependencies"),
                                        a.getOptionalList("libs"),
                                        a.byOptionalKey("active", true), //true for backwards compatibility
                            )).
                   filter!(a => a.active).
                   array);
}


private string[] jsonValueToFiles(JSONValue files) @trusted {
    return files.array.
        filter!(a => a.byKey("type").str == "source").
        map!(a => a.byKey("path").str).
        array;
}

private string[] jsonValueToStrings(JSONValue json) @trusted {
    return json.array.map!(a => a.str).array;
}


private auto byKey(JSONValue json, in string key) @trusted {
    return json.object[key];
}

private auto byOptionalKey(JSONValue json, in string key, bool def) {
    import std.conv: to;
    auto value = json.object;
    return key in value ? value[key].boolean : def;
}

//std.json has no conversion to bool
private bool boolean(JSONValue json) @trusted {
    import std.exception: enforce;
    enforce!JSONException(json.type == JSON_TYPE.TRUE || json.type == JSON_TYPE.FALSE,
                          "JSONValue is not a boolean");
    return json.type == JSON_TYPE.TRUE;
}

private string getOptional(JSONValue json, in string key) @trusted {
    auto aa = json.object;
    return key in aa ? aa[key].str : "";
}

private string[] getOptionalList(JSONValue json, in string key) @trusted {
    auto aa = json.object;
    return key in aa ? aa[key].jsonValueToStrings : [];
}
