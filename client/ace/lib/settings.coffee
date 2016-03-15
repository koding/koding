syntaxAssociations = require './settings-syntax-associations'


module.exports =

  compilerCallNames:
    coffee    :
      class   : 'CoffeeScript'
      method  : 'compile'
      options :
        bare  : on

  fontSizes: [
      value: 10
      title: '10px'
    ,
      value: 11
      title: '11px'
    ,
      value: 12
      title: '12px'
    ,
      value: 14
      title: '14px'
    ,
      value: 16
      title: '16px'
    ,
      value: 20
      title: '20px'
    ,
      value: 24
      title: '24px'
  ]

  tabSizes: [
      value: 2
      title: '2 chars'
    ,
      value: 4
      title: '4 chars'
    ,
      value: 8
      title: '8 chars'
  ]

  keyboardHandlers: [
      value: 'default'
      title: 'Default'
    ,
      value: 'vim'
      title: 'Vim'
    ,
      value: 'emacs'
      title: 'Emacs'
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

  syntaxAssociations : syntaxAssociations

  getSyntaxOptions : ->

    o = for own syntax, info of syntaxAssociations
      { title : info[0], value : syntax }

    o.sort (a, b) -> if a.title < b.title then -1 else 1

    return o

  aceToHighlightJsSyntaxMap :

    coffee      : 'coffee'
    # coldfusion: null
    csharp      : 'cs'
    css         : 'css'
    diff        : 'diff'
    dart        : 'dart'
    golang      : 'go'
    # groovy    : null
    # haxe      : null
    haml        : 'haml'
    html        : 'xml'
    c_cpp       : 'cpp'
    # clojure   : null
    jade        : 'jade'
    java        : 'java'
    javascript  : 'javascript'
    json        : 'javascript'
    # json      : 'json'
    latex       : 'tex'
    go          : 'golang'
    less        : 'css'
    lisp        : 'lisp'
    livescript  : 'ls'
    # liquid    : null
    lua         : 'lua'
    markdown    : 'markdown'
    ocaml       : 'ocaml'
    pascal      : 'pascal'
    perl        : 'perl'
    pgsql       : 'sql'
    php         : 'php'
    powershell  : 'bash'
    python      : 'python'
    r           : 'r'
    rhtml       : 'rhtml'
    ruby        : 'ruby'
    # scad      : null
    scala       : 'scala'
    scss        : 'css'
    stylus      : 'stylus'
    sh          : 'bash'
    sql         : 'sql'
    typescript  : 'ts'
    # svg       : null
    # text      : null
    # textile   : null
    xml         : 'xml'
    objectivec  : 'objectivec'
    # xquery    : null
    # yaml      : null
