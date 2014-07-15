IDE.settings or= {}

IDE.settings.editor =

  softWrapOptions: [
    { value: 'off',      title: 'Off'      }
    { value: 40,         title: '40 chars' }
    { value: 80,         title: '80 chars' }
    { value: 'free',     title: 'Free'     }
  ]

  fontSizes: [
    { value: 10,         title: '10px'     }
    { value: 11,         title: '11px'     }
    { value: 12,         title: '12px'     }
    { value: 14,         title: '14px'     }
    { value: 16,         title: '16px'     }
    { value: 20,         title: '20px'     }
    { value: 24,         title: '24px'     }
  ]

  tabSizes: [
    { value: 2,          title: '2 chars'  }
    { value: 4,          title: '4 chars'  }
    { value: 8,          title: '8 chars'  }
  ]

  keyboardHandlers: [
    { value: "default",  title: "Default"  }
    { value: "vim",      title: "Vim"      }
    { value: "emacs",    title: "Emacs"    }
  ]

  themes:
    Bright : [
      { title: 'Chrome',                value: 'chrome' }
      { title: 'Clouds',                value: 'clouds' }
      { title: 'Crimson Editor',        value: 'crimson_editor' }
      { title: 'Dawn',                  value: 'dawn' }
      { title: 'Dreamweaver',           value: 'dreamweaver' }
      { title: 'Eclipse',               value: 'eclipse' }
      { title: 'GitHub',                value: 'github' }
      { title: 'Solarized Light',       value: 'solarized_light' }
      { title: 'TextMate',              value: 'textmate' }
      { title: 'Tomorrow',              value: 'tomorrow' }
      { title: 'XCode',                 value: 'xcode' }
    ].sort (a, b) -> if a.title < b.title then -1 else 1

    Dark : [
      { title: 'Ambiance',              value: 'ambiance' }
      { title: 'Clouds Midnight',       value: 'clouds_midnight' }
      { title: 'Cobalt',                value: 'cobalt' }
      { title: 'Idle Fingers',          value: 'idle_fingers' }
      { title: 'KR Theme',              value: 'kr_theme' }
      { title: 'Koding',                value: 'koding' }
      { title: 'Merbivore',             value: 'merbivore' }
      { title: 'Merbivore Soft',        value: 'merbivore_soft' }
      { title: 'Mono Industrial',       value: 'mono_industrial' }
      { title: 'Monokai',               value: 'monokai' }
      { title: 'Pastel on Dark',        value: 'pastel_on_dark' }
      { title: 'Solarized Dark',        value: 'solarized_dark' }
      { title: 'Twilight',              value: 'twilight' }
      { title: 'Tomorrow Night',        value: 'tomorrow_night' }
      { title: 'Tomorrow Night Blue',   value: 'tomorrow_night_blue' }
      { title: 'Tomorrow Night Bright', value: 'tomorrow_night_bright' }
      { title: 'Tomorrow Night 80s',    value: 'tomorrow_night_eighties' }
      { title: 'Vibrant Ink',           value: 'vibrant_ink' }
    ].sort (a, b) -> if a.title < b.title then -1 else 1


  syntaxAssociations :

    abap        : ["ABAP"         , "abap"]
    asciidoc    : ["ASCIIDoc"     , "AsciiDoc"]
    coffee      : ["CoffeeScript" , "coffee|Cakefile"]
    coldfusion  : ["ColdFusion"   , "cfm"]
    csharp      : ["C#"           , "cs"]
    css         : ["CSS"          , "css"]
    dart        : ["Dart"         , "dart"]
    diff        : ["Diff"         , "diff|patch"]
    golang      : ["Go"           , "go"]
    glsl        : ["GLSL"         , "glsl"]
    groovy      : ["Groovy"       , "groovy"]
    haxe        : ["haXe"         , "hx"]
    haml        : ["HAML"         , "haml"]
    html        : ["HTML"         , "htm|html|xhtml"]
    c_cpp       : ["C/C++"        , "c|cc|cpp|cxx|h|hh|hpp"]
    clojure     : ["Clojure"      , "clj"]
    delphi      : ["Delphi"       , "delphi"]
    jade        : ["Jade"         , "jade"]
    java        : ["Java"         , "java"]
    javascript  : ["JavaScript"   , "js"]
    json        : ["JSON"         , "json|manifest|kdapp"]
    jsx         : ["JSX"          , "jsx"]
    latex       : ["LaTeX"        , "latex|tex|ltx|bib"]
    less        : ["LESS"         , "less"]
    liquid      : ["Liquid"       , "liquid"]
    lisp        : ["Lisp"         , "lisp"]
    lucene      : ["Lucene"       , "cfs"]
    lua         : ["Lua"          , "lua"]
    luapage     : ["LuaPage"      , "lp"]
    makefile    : ["MAKEFILE"     , "makefile"]
    markdown    : ["Markdown"     , "md|markdown"]
    ocaml       : ["OCaml"        , "ml|mli"]
    perl        : ["Perl"         , "pl|pm"]
    pgsql       : ["pgSQL"        , "pgsql"]
    php         : ["PHP"          , "php|phtml"]
    rhtml       : ["RHTML"        , "rhtml"]
    r           : ["R"            , "r"]
    rdoc        : ["RDOC"         , "rdoc"]
    powershell  : ["Powershell"   , "ps1"]
    python      : ["Python"       , "py"]
    ruby        : ["Ruby"         , "ru|gemspec|rake|rb|erb"]
    scad        : ["OpenSCAD"     , "scad"]
    scala       : ["Scala"        , "scala"]
    scss        : ["SCSS"         , "scss|sass"]
    stylus      : ["Stylus"       , "styl"]
    sh          : ["SH"           , "sh|bash|bat"]
    sql         : ["SQL"          , "sql"]
    svg         : ["SVG"          , "svg"]
    tex         : ["TeX"          , "tex"]
    text        : ["Text"         , "txt"]
    textile     : ["Textile"      , "textile"]
    typescript  : ["Typescript"   , "ts"]
    xml         : ["XML"          , "xml|rdf|rss|wsdl|xslt|atom|mathml|mml|xul|xbl"]
    xquery      : ["XQuery"       , "xq"]
    yaml        : ["YAML"         , "yaml|yml"]
    objectivec  : ["Objective C"  , "__dummy__"]

  getAllExts : ->
    exts = (IDE.settings.editor.syntaxAssociations[key][1].split "|" for key in Object.keys IDE.settings.editor.syntaxAssociations)
    exts = [].concat exts...
    exts = (v.toLowerCase() for v in exts)
    exts = _.unique exts

  getSyntaxOptions : ->

    o = for own syntax, info of __aceSettings.syntaxAssociations
      { title : info[0], value : syntax }

    o.sort (a, b) -> if a.title < b.title then -1 else 1

    return o

  aceToHighlightJsSyntaxMap :

    coffee      : "coffee"
    # coldfusion  : null
    csharp      : "cs"
    css         : "css"
    diff        : "diff"
    dart        : "dart"
    golang      : "go"
    # groovy      : null
    # haxe        : null
    haml        : "haml"
    html        : "xml"
    c_cpp       : "cpp"
    # clojure     : null
    jade        : "jade"
    java        : "java"
    javascript  : "javascript"
    json        : "javascript"
    # json        : "json"
    latex       : "tex"
    go          : "golang"
    less        : "css"
    lisp        : "lisp"
    # liquid      : null
    lua         : "lua"
    markdown    : "markdown"
    ocaml       : "ocaml"
    perl        : "perl"
    pgsql       : "sql"
    php         : "php"
    powershell  : "bash"
    python      : "python"
    r           : "r"
    rhtml       : "rhtml"
    ruby        : "ruby"
    # scad        : null
    scala       : "scala"
    scss        : "css"
    stylus      : "stylus"
    sh          : "bash"
    sql         : "sql"
    typescript  : "ts"
    # svg         : null
    # text        : null
    # textile     : null
    xml         : "xml"
    objectivec  : "objectivec"
    # xquery      : null
    # yaml        : null

  ignoreDirectories: {
    ".bzr"              : "Bazaar",
    ".cdv"              : "Codeville",
    "~.dep"             : "Interface Builder",
    "~.dot"             : "Interface Builder",
    "~.nib"             : "Interface Builder",
    "~.plst"            : "Interface Builder",
    ".git"              : "Git",
    ".hg"               : "Mercurial",
    ".pc"               : "quilt",
    ".svn"              : "Subversion",
    "_MTN"              : "Monotone",
    "blib"              : "Perl module building",
    "CVS"               : "CVS",
    "RCS"               : "RCS",
    "SCCS"              : "SCCS",
    "_darcs"            : "darcs",
    "_sgbak"            : "Vault/Fortress",
    "autom4te.cache"    : "autoconf",
    "cover_db"          : "Devel::Cover",
    "_build"            : "Module::Build",
    "node_modules"      : "Node"
  }
