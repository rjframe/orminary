import reggae;
import reggae.config : options;


// TODO: reggae isn't running d2sqlite3's preBuildCommands; currently in Travis
// but needs to be fixed.

static if (userVars.get("SqLite", "true") == "true") {
    enum sqlite = " -version=SqLite";
} else enum sqlite = "";

static if (userVars.get("MySQL", "true") == "true") {
    enum mysql = " -version=MySQL";
} else enum mysql = "";

static if (userVars.get("Postgres", "true") == "true") {
    enum postgres = " -version=Postgres";
} else enum postgres = "";


enum debugFlag = options.dCompiler == "dmd" ? "-debug" : "-d-debug";
enum flags = debugFlag ~ " -g -w" ~ sqlite ~ mysql ~ postgres;

// TODO: Finish customized builds; we are still linking all DB libraries.
// Once done (via not using the dub targets) I can change the d2sqlite target
// above to phony and not need to change the directory every time I update.

// Dub configurations: build everything and unit tests.
alias allOrm = dubDefaultTarget!(CompilerFlags(flags));
alias test = dubTestTarget!(CompilerFlags(flags));

mixin build!(allOrm, test);

