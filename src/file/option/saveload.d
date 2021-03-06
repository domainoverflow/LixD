module file.option.saveload;

import std.file;
import std.string;

import sdlang;

import basics.globals;
import file.backup;
import file.option.allopts;
import file.option.load2017;
import file.log;
import hardware.tharsis;

void loadUserOptions()
{
    try {
        loadUserOptionsSdlang();
    }
    catch (FileException e) {
        log("Can't options file: " ~ fileOptions.rootless);
        log("    -> " ~ e.msg.replace(": Bad address", "File doesn't exist"));
        loadUserName2017format();
        loadUserOptions2017format();
    }
    catch (Exception e) {
        log("Syntax errors in options file: " ~ fileOptions.rootless);
        log("    -> " ~ e.msg);
        backupBrokenSdlang(fileOptions, e);
    }
}

nothrow void saveUserOptions()
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "save options SDLang");
    try {
        auto root = new Tag();
        foreach (opt; _optvecSave) {
            root.add(opt.createTag);
        }
        auto f = fileOptions.openForWriting;
        f.write(root.toSDLDocument);
    }
    catch (Exception e) {
        log("Can't save options to: " ~ fileOptions.rootless);
        log("    -> " ~ e.msg);
    }
}

///////////////////////////////////////////////////////////////////////////////

private:

// Can throw FileException or SDLang's own exceptions.
void loadUserOptionsSdlang()
{
    version (tharsisprofiling)
        auto zone = Zone(profiler, "load options SDLang");
    auto root = sdlang.parseFile(fileOptions.stringForReading);
    foreach (tag; root.tags)
        if (auto opt = tag.name in _optvecLoad)
            opt.set(tag);
}
