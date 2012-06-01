__aceData =    

  compilerCallNames: 
    coffee    :
      class   : 'CoffeeScript'
      method  : 'compile'
      options : 
        bare  : on

  syntaxExtensionAssociations: 
    php:          ['php', 'phtml']
    css:          ['css']
    javascript:   ['js']
    coffee:       ['coffee']
    c:            ['c_cpp']
    html:         ['html', 'htm', 'xhtml']
    java:         ['j', 'java']
    perl:         ['perl']
    python:       ['pyth']
    ruby:         ['rb']
    svg:          ['svg']
    xml:          ['xml']
    scss:         ['scss']
  
  softWrapOptions: [
      value: 'off'
      title: 'Off'
    ,
      value: 40
      title: '40 chars'
    ,
      value: 80
      title: '80 chars'
    ,
      value: 'free'
      title: 'Free'
  ]  
  
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
  
  syntaxes: [
      value: 'c_cpp'
      title: 'C++'
    ,
      value: 'javascript'
      title: 'Javascript'
    ,
      value: 'json'
      title: 'JSON'
    ,
      value: 'coffee'
      title: 'Coffee-script'
    ,
      value: 'css'
      title: 'CSS'
    ,
      value: 'html'
      title: 'HTML'
    ,
      value: 'java'
      title: 'Java'
    ,
      value: 'perl'
      title: 'Perl'
    ,
      value: 'php'
      title: 'PHP'
    ,
      value: 'python'
      title: 'Python'
    ,
      value: 'scss'
      title: 'SCSS'
    ,
      value: 'ruby'
      title: 'Ruby'
    ,
      value: 'svg'
      title: 'SVG'
    ,
      value: 'xml'
      title: 'XML'
    ,
      value: 'groovy'
      title: 'Groovy'
    ,
      value: 'ocaml'
      title: 'Ocaml'
    ,
      value: 'scad'
      title: 'Scad'
    ,
      value: 'scala'
      title: 'Scala'
    , 
      title: 'ColdFusion'
      value: 'coldfusion'
    , 
      value: 'haxe'
      title: 'Haxe'
    ,
      value: 'latex'
      title: 'Latex'
    ,
      title: 'Lua'
      value: 'lua'
    ,
      title: 'Markdown'
      value: 'markdown'
    ,
      title: 'PowerShell'
      value: 'powershell'
    ,
      title: 'SQL'
      value: 'sql'
    ].sort (a, b) ->
      if a.title < b.title then -1 else 1
  themes: [
      value: 'clouds'
      title: 'Clouds'
    ,
      value: 'clouds_midnight'
      title: 'Clouds Midnight'
    ,
      value: 'cobalt'
      title: 'Cobalt'
    ,
      value: 'dawn'
      title: 'Dawn'
    ,
      value: 'eclipse'
      title: 'Eclipse'
    ,
      value: 'idle_fingers'
      title: 'Idle Fingers'
    ,
      value: 'kr_theme'
      title: 'KR Theme'
    ,
      value: 'merbivore'
      title: 'Merbivore'
    ,
      value: 'merbivore_soft'
      title: 'Merbivore Soft'
    ,
      value: 'mono_industrial'
      title: 'Mono Industrial'
    ,
      value: 'monokai'
      title: 'Monokai'
    ,
      value: 'pastel_on_dark'
      title: 'Pastel On Dark'
    ,
      value: 'twilight'
      title: 'Twilight'
    ,
      value: 'vibrant_ink'
      title: 'Vibtrant Ink'
    ,
      value: 'crimson_editor'
      title: 'Crimson Editor'
    ,
      value: 'solarized_dark'
      title: 'Solarized Dark'
    ,
      value: 'solarized_light'
      title: 'Solarized Light'
    ,
      title: 'Tomorrow'
      value: 'tomorrow'
    ,
      title: 'Tomorrow Night'
      value: 'tomorrow_night'
    ,
      title: 'Tomorrow Night Blue'
      value: 'tomorrow_night_blue'
    ,
      title: 'Tomorrow Night Bright'
      value: 'tomorrow_night_bright'
    ,
      title: 'Tomorrow Night Eighties'
      value: 'tomorrow_night_eighties'
    ].sort (a, b) ->
      if a.title < b.title then -1 else 1
