framework = requirejs 'Framework'
{
  KDView
  KDViewController
  KDButtonMenu
  KDButtonViewWithMenu
  KDDialogView
  KDFormView
  KDHeaderView
  KDInputSwitch
  KDInputView
  KDLabelView
  KDModalView
  KDNotificationView
  KDRySwitch
  KDScrollView
  KDSelectBox
  KDContextMenuTreeView
  KDContextMenuTreeViewController
  # FinderController
  JsPath
} = framework

availableModes = [
  { title : 'C, C++, Java, and similar'          ,value : 'clike'}
  { title : "Clojure"                            ,value : 'clojure'}
  { title : 'CoffeeScript'                       ,value : 'coffeescript'}
  { title : 'CSS'                                ,value : 'css'}
  { title : 'diff'                               ,value : 'diff'}
  { title : 'ECL'                                ,value : 'gfm'}
  { title : 'Go'                                 ,value : 'go'}
  { title : 'Groovy'                             ,value : 'groovy'}
  { title : 'Haskell'                            ,value : 'haskell'}
  { title : 'HTML mixed-mode'                    ,value : 'htmlmixed'}
  { title : 'JavaScript'                         ,value : 'javascript'}
  { title : 'Jinja2'                             ,value : 'jinja2'}
  { title : 'LESS'                               ,value : 'less'}
  { title : 'Lua'                                ,value : 'lua'}
  { title : 'Markdown (Github-flavour)'          ,value : 'markdown'}
  { title : 'MySQL'                              ,value : 'mysql'}
  { title : 'NTriples'                           ,value : 'ntriples'}
  { title : 'Pascal'                             ,value : 'pascal'}
  { title : 'Perl'                               ,value : 'perl'}
  { title : 'PHP'                                ,value : 'php'}
  { title : 'PL/SQL'                             ,value : 'plsql'}
  { title : 'Plain Text'                         ,value : 'text/plain'}
  { title : 'Properties files'                   ,value : 'xmlpure'}
  { title : 'Python'                             ,value : 'python'}
  { title : 'R'                                  ,value : 'r'}
  { title : 'RPM spec'                           ,value : 'rpm/spec'}
  { title : 'RPM changelog'                      ,value : 'rpm/changes'}
  { title : 'reStructuredText'                   ,value : 'rst'}
  { title : 'Ruby'                               ,value : 'ruby'}
  { title : 'Rust'                               ,value : 'rust'}
  { title : 'Scheme'                             ,value : 'scheme'}
  { title : 'Smalltalk'                          ,value : 'smalltalk'}
  { title : 'SPARQL'                             ,value : 'sparql'}
  { title : 'sTeX, LaTeX'                        ,value : 'stex'}
  { title : 'Tiddlywiki'                         ,value : 'tiddlywiki'}
  { title : 'Velocity'                           ,value : 'velocity'}
  { title : 'Verilog'                            ,value : 'verilog'}
  { title : 'XML/HTML (alternative XML)'         ,value : 'xml'}
  { title : 'YAML'                               ,value : 'yaml'}
]

modeDependencies = {
  htmlmixed     :
    javascript  : ['htmlmixed', 'javascript', 'css', 'xml']
  php           :
    javascript  : ['php', 'javascript', 'css', 'xml', 'clike']
  'rpm/spec'    :
    javascript  : ['rpm/spec']
    css         : ['rpm/spec']
  diff          :
    javascript  : ['diff']
    css         : ['diff']
  tiddlywiki    :
    javascript  : ['tiddlywiki']
    css         : ['tiddlywiki']
}

availableThemes = [
  { title : 'Cobalt'                ,value : 'cobalt'  }
  { title : 'Eclipse'               ,value : 'eclipse' }
  { title : 'Elegant'               ,value : 'elegant' }
  { title : 'Monokai'               ,value : 'monokai' }
  { title : 'Neat'                  ,value : 'neat'    }
  { title : 'Night'                 ,value : 'night'   }
  { title : 'Rubyblue'              ,value : 'rubyblue'}
]

environment = null
storage = null

defaultStorage = 
  appOptions :
    visualPreferences :
      theme                 : 'cobalt'
      matchBrackets         : yes
      lineWrapping          : no
      lineNumbers           : no #reason for this default is that codemirror doesn't seem to turn them off once they're on in an instance...?-sah 2/22/12
      mode                  : 'text/plain'
    textPreferences :
      indentWithTabs        : yes
      smartIndent           : yes
      tabSize               : 2