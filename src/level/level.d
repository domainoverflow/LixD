module level.level;

import enumap;

public import level.levelio : saveToFile;

import basics.topology;
import file.date;
import file.filename;
import file.language;
import tile.phymap;
import graphic.color;
import graphic.torbit;
import level.addtile;
import level.levelio;
import level.levdraw;
import tile.occur;
import tile.gadtile;
import tile.tilelib : get_filename;
import lix.enums;

enum LevelStatus {
    GOOD,
    BAD_HATCH,          // level doens't contain >= 1 hatch
    BAD_GOAL,           // level doesn't contain >= 1 goal
    BAD_IMAGE,          // can't load all necessary tile images from disk
    BAD_FILE_NOT_FOUND, // can't load the level, level file not found
    BAD_EMPTY           // file exists, but no tiles
}

enum FileFormat {
    NOTHING,
    LIX,
    BINARY,
    LEMMINI
}

class Level {
public:
    static immutable int minXl = 160;
    static immutable int minYl = 160;
    static immutable int maxXl = 3200;
    static immutable int maxYl = 2000;
    static immutable int spawnintMin =  1;
    static immutable int spawnintMax = 96;

    // DTODO: implement players_intended;
    MutableDate built;
    string author;
    string nameGerman;
    string nameEnglish;

    string[] hintsGerman;
    string[] hintsEnglish;

    Topology topology;
    int  bgRed;
    int  bgGreen;
    int  bgBlue;

    int  seconds;
    int  initial;
    int  required;
    int  spawnintSlow;
    int  spawnintFast;

    bool useManualScreenStart;
    Point manualScreenStartCenter;

    /* ploder: either Ac.exploder or Ac.imploder.
     * This is never written to the level file. Instead, 0 exploders or 0
     * imploders should always be written to file. If both are missing,
     * this should offer flingploder.
     */
    Ac ploder;

    Enumap!(Ac, int) skills;

    TerOcc[] terrain;
    GadOcc[][GadType.MAX] pos; // one array GadOcc[] for each GadType,
                               // indexed by ints, not by GadType enum vals
package:
    LevelStatus _status;

public:
    this()
    {
        built   = Date.now();
        _status = LevelStatus.BAD_EMPTY;
        topology = new Topology(640, 400); // one screen in C++ Lix
        initial      =  30;
        required     =  20;
        spawnintSlow =  32;
        spawnintFast =   4;
        ploder       = Ac.exploder;
    }

    this(in Filename fn)
    {
        this();
        level.levelio.loadFromFile(this, fn);
    }

    @property string
    name() const
    {
        // DTODOLANG
        // if (Lang.get_current() == Language.GERMAN)
        //      return nameGerman  == null ? nameEnglish : nameGerman;
        return nameEnglish == null ? nameGerman  : nameEnglish;
    }

    @property inout(string[])
    hints() inout
    {
        // DTODOLANG
        // if (Lang.get_current() == Language.GERMAN)
        //      return hintsGerman  == null ? hintsEnglish : hintsGerman;
        return hintsEnglish == null ? hintsGerman  : hintsEnglish;
    }

    @property LevelStatus status() const { return _status; }
    @property bool        good()   const { return _status == LevelStatus.GOOD;}

    @property bool nonempty() const
    {
        return _status != LevelStatus.BAD_FILE_NOT_FOUND
            && _status != LevelStatus.BAD_EMPTY;
    }

    // Called from the Editor. Adds to the correct array of this level,
    // then returns, in addition, a reference to the added piece.
    Occurrence addTileWithCenterAt(Filename fn, Point p)
    {
        return implCenter(this, fn, p);
    }

    void drawTerrainTo(Torbit tb, Phymap lo = null) const
    {
        implDrawTerrainTo(this, tb, lo);
    }

    Torbit create_preview(in int xl, in int yl, AlCol col) const
    {
        return implCreatePreview(this, xl, yl, col);
    }

    // void load_from_stream(std::istream&); DTODO: implement this?
    void saveToFile (in Filename fn) const { implSaveToFile (this, fn); }
    void exportImage(in Filename fn) const { implExportImage(this, fn); }

    // to save a level into a replay, call with existing File descriptor:
    // mylevel.saveToFile(std.stdio.File existing_handle)

    override bool
    opEquals(Object rhs_obj) const
    {
        const(Level) rhs = cast (const Level) rhs_obj;
        if (rhs_obj is null) return false;
        if (   this.author       != rhs.author
            || this.nameGerman   != rhs.nameGerman
            || this.nameEnglish  != rhs.nameEnglish
            || this.hintsGerman  != rhs.hintsGerman
            || this.hintsEnglish != rhs.hintsEnglish

            || this.topology     != rhs.topology
            || this.bgRed        != rhs.bgRed
            || this.bgGreen      != rhs.bgGreen
            || this.bgBlue       != rhs.bgBlue

            || this.seconds      != rhs.seconds
            || this.initial      != rhs.initial
            || this.required     != rhs.required
            || this.spawnintSlow != rhs.spawnintSlow
            || this.spawnintFast != rhs.spawnintFast
            || this.ploder       != rhs.ploder
        ) {
            return false;
        }
        // We don't care about a difference in the manual screen position if
        // we rely on automatic screen start anyway in both levels.
        if (this.useManualScreenStart != rhs.useManualScreenStart
            || this.useManualScreenStart
            && this.manualScreenStartCenter != rhs.manualScreenStartCenter
        ) {
            return false;
        }
        // compare all tiles in one go
        if (this.pos    != rhs.pos   ) return false;
        if (this.skills != rhs.skills) return false;
        return true;
    }
}
// end class Level
