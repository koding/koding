class AppControllerOptions

  name        : 'IDE'
  behavior    : 'application'
  multiple    : yes
  preCondition:
    condition  : (options, cb) -> cb KD.isLoggedIn()
    failure    : (options, cb) ->
      KD.getSingleton('appManager').open 'IDE', conditionPassed : yes
      KD.showEnforceLoginModal()
  commands:
    'find file by name'   : 'showFileFinder'
    'search all files'    : 'showContentSearch'
    'split vertically'    : 'splitVertically'
    'split horizontally'  : 'splitHorizontally'
    'merge splitview'     : 'mergeSplitView'
    'preview file'        : 'previewFile'
    'save all files'      : 'saveAllFiles'
    'create new file'     : 'createNewFile'
    'create new terminal' : 'createNewTerminal'
    'create new drawing'  : 'createNewDrawing'
    'collapse sidebar'    : 'collapseSidebar'
    'expand sidebar'      : 'expandSidebar'
    'toggle sidebar'      : 'toggleSidebar'
    'close tab'           : 'closeTab'
    'go to left tab'      : 'goToLeftTab'
    'go to right tab'     : 'goToRightTab'
    'go to tab number'    : 'goToTabNumber'
    'fullscren ideview'   : 'toggleFullscreenIDEView'
    'move tab up'         : 'moveTabUp'
    'move tab down'       : 'moveTabDown'
    'move tab left'       : 'moveTabLeft'
    'move tab right'      : 'moveTabRight'

  keyBindings: [
    { command: 'find file by name',   binding: 'ctrl+alt+o',           global: yes }
    { command: 'search all files',    binding: 'ctrl+alt+f',           global: yes }
    { command: 'split vertically',    binding: 'ctrl+alt+v',           global: yes }
    { command: 'split horizontally',  binding: 'ctrl+alt+h',           global: yes }
    { command: 'merge splitview',     binding: 'ctrl+alt+m',           global: yes }
    { command: 'preview file',        binding: 'ctrl+alt+p',           global: yes }
    { command: 'save all files',      binding: 'ctrl+alt+s',           global: yes }
    { command: 'create new file',     binding: 'ctrl+alt+n',           global: yes }
    { command: 'create new terminal', binding: 'ctrl+alt+t',           global: yes }
    { command: 'create new browser',  binding: 'ctrl+alt+b',           global: yes }
    { command: 'create new drawing',  binding: 'ctrl+alt+d',           global: yes }
    { command: 'toggle sidebar',      binding: 'ctrl+alt+k',           global: yes }
    { command: 'close tab',           binding: 'ctrl+alt+w',           global: yes }
    { command: 'go to left tab',      binding: 'ctrl+alt+[',           global: yes }
    { command: 'go to right tab',     binding: 'ctrl+alt+]',           global: yes }
    { command: 'go to tab number',    binding: 'mod+1',                global: yes }
    { command: 'go to tab number',    binding: 'mod+2',                global: yes }
    { command: 'go to tab number',    binding: 'mod+3',                global: yes }
    { command: 'go to tab number',    binding: 'mod+4',                global: yes }
    { command: 'go to tab number',    binding: 'mod+5',                global: yes }
    { command: 'go to tab number',    binding: 'mod+6',                global: yes }
    { command: 'go to tab number',    binding: 'mod+7',                global: yes }
    { command: 'go to tab number',    binding: 'mod+8',                global: yes }
    { command: 'go to tab number',    binding: 'mod+9',                global: yes }
    { command: 'fullscren ideview',   binding: 'mod+shift+enter',      global: yes }
    { command: 'move tab up',         binding: 'mod+alt+shift+up',     global: yes }
    { command: 'move tab down',       binding: 'mod+alt+shift+down',   global: yes }
    { command: 'move tab left',       binding: 'mod+alt+shift+left',   global: yes }
    { command: 'move tab right',      binding: 'mod+alt+shift+right',  global: yes }
  ]


module.exports = AppControllerOptions
