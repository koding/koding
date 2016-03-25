_ = require 'lodash'

module.exports =

  fontSizes: [
    { value: 10,         title: '10px' }
    { value: 11,         title: '11px' }
    { value: 12,         title: '12px' }
    { value: 14,         title: '14px' }
    { value: 16,         title: '16px' }
    { value: 20,         title: '20px' }
    { value: 24,         title: '24px' }
  ]

  tabSizes: [
    { value: 2,          title: '2 chars' }
    { value: 4,          title: '4 chars' }
    { value: 8,          title: '8 chars' }
  ]

  keyboardHandlers: [
    { value: 'default',  title: 'Default' }
    { value: 'vim',      title: 'Vim' }
    { value: 'emacs',    title: 'Emacs' }
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
      { title: 'Base16',                value: 'base16' }
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

    abap        : ['ABAP'         , 'abap']
    actionscript: ['ActionScript' , 'as']
    ada         : ['Ada'          , 'ada']
    asciidoc    : ['ASCIIDoc'     , 'AsciiDoc']
    assembly_x86: ['Assembly'     , 'a86']
    batchfile   : ['Batch File'   , 'bat']
    c_cpp       : ['C/C++'        , 'c|cc|cpp|cxx|h|hh|hpp']
    clojure     : ['Clojure'      , 'clj']
    cobol       : ['Cobol'        , 'cobol']
    coffee      : ['CoffeeScript' , 'coffee|Cakefile']
    coldfusion  : ['ColdFusion'   , 'cfm']
    csharp      : ['C#'           , 'cs']
    css         : ['CSS'          , 'css']
    dart        : ['Dart'         , 'dart']
    delphi      : ['Delphi'       , 'delphi']
    diff        : ['Diff'         , 'diff|patch']
    erlang      : ['Erlang'       , 'erl']
    fortran     : ['Fortran'      , 'f|for|f77|f90|f95|f03|f2k']
    glsl        : ['GLSL'         , 'glsl']
    golang      : ['Go'           , 'go']
    groovy      : ['Groovy"'      , 'groovy']
    haml        : ['Haml'         , 'haml']
    haskell     : ['Haskell'      , 'hs']
    haxe        : ['haXe'         , 'hx']
    html        : ['HTML'         , 'htm|html|xhtml']
    jade        : ['Jade'         , 'jade']
    java        : ['Java'         , 'java']
    javascript  : ['JavaScript'   , 'js']
    json        : ['JSON'         , 'json|manifest|kdapp']
    jsp         : ['JSP'          , 'jsp']
    jsx         : ['JSX'          , 'jsx']
    julia       : ['Julia'        , 'jl']
    latex       : ['LaTeX'        , 'latex|tex|ltx|bib']
    less        : ['LESS'         , 'less']
    liquid      : ['Liquid'       , 'liquid']
    lisp        : ['Lisp'         , 'lisp']
    livescript  : ['LiveScript'   , 'ls']
    lua         : ['Lua'          , 'lua']
    luapage     : ['LuaPage'      , 'lp']
    lucene      : ['Lucene'       , 'cfs']
    makefile    : ['MAKEFILE'     , 'makefile']
    markdown    : ['Markdown'     , 'md|markdown']
    objectivec  : ['Objective C'  , 'm|mm|h']
    ocaml       : ['OCaml'        , 'ml|mli']
    pascal      : ['Pascal'       , 'pas']
    perl        : ['Perl'         , 'pl|pm']
    pgsql       : ['pgSQL'        , 'pgsql']
    php         : ['PHP'          , 'php|phtml']
    powershell  : ['Powershell'   , 'ps1']
    python      : ['Python'       , 'py']
    r           : ['R'            , 'r']
    rdoc        : ['RDOC'         , 'rdoc']
    rhtml       : ['RHTML'        , 'rhtml']
    ruby        : ['Ruby'         , 'ru|gemspec|rake|rb|erb']
    scad        : ['OpenSCAD'     , 'scad']
    scala       : ['Scala'        , 'scala']
    scss        : ['SCSS'         , 'scss|sass']
    sh          : ['SH'           , 'sh|bash|bat']
    sql         : ['SQL'          , 'sql']
    stylus      : ['Stylus'       , 'styl']
    svg         : ['SVG'          , 'svg']
    tcl         : ['TCL/Tk'       , 'tcl|tk']
    tex         : ['TeX'          , 'tex']
    text        : ['Text'         , 'txt']
    textile     : ['Textile'      , 'textile']
    typescript  : ['Typescript'   , 'ts']
    xml         : ['XML'          , 'xml|rdf|rss|wsdl|xslt|atom|mathml|mml|xul|xbl']
    xquery      : ['XQuery'       , 'xq']
    yaml        : ['YAML'         , 'yaml|yml']

  getAllExts : ->
    exts = (@syntaxAssociations[key][1].split '|' for key in Object.keys @syntaxAssociations)
    exts = [].concat exts...
    exts = (v.toLowerCase() for v in exts)
    exts = _.uniq exts

  getSyntaxOptions : ->

    o = for own syntax, info of @syntaxAssociations
      { title : info[0], value : syntax }

    o.sort (a, b) -> if a.title < b.title then -1 else 1

    return o

  ignoreDirectories: {
    '.bzr'              : 'Bazaar',
    '.cdv'              : 'Codeville',
    '~.dep'             : 'Interface Builder',
    '~.dot'             : 'Interface Builder',
    '~.nib'             : 'Interface Builder',
    '~.plst'            : 'Interface Builder',
    '.git'              : 'Git',
    '.hg'               : 'Mercurial',
    '.pc'               : 'quilt',
    '.svn'              : 'Subversion',
    '_MTN'              : 'Monotone',
    'blib'              : 'Perl module building',
    'CVS'               : 'CVS',
    'RCS'               : 'RCS',
    'SCCS'              : 'SCCS',
    '_darcs'            : 'darcs',
    '_sgbak'            : 'Vault/Fortress',
    'autom4te.cache'    : 'autoconf',
    'cover_db'          : 'Devel::Cover',
    '_build'            : 'Module::Build',
    'node_modules'      : 'Node'
  }
