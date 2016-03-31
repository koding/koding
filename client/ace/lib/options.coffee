module.exports =
  name          : 'Ace'
  multiple      : yes
  hiddenHandle  : no
  openWith      : 'lastActive'
  behavior      : 'application'
  menu          : [
    { title     : 'Save',                eventName : 'save' }
    { title     : 'Save as...',          eventName : 'saveAs' }
    { title     : 'Save All',            eventName : 'saveAll' }
    { type      : 'separator' }
    { title     : 'Find',                eventName : 'find' }
    { title     : 'Find and replace...', eventName : 'findAndReplace' }
    { title     : 'Go to line',          eventName : 'gotoLine' }
    { type      : 'separator' }
    { title     : 'Preview',             eventName : 'preview' }
    { type      : 'separator' }
    { title     : 'Key Bindings',        eventName : 'keyBindings' }
    { type      : 'separator' }
    { title     : 'Advanced settings',   id        : 'advancedSettings' }
    { title     : 'customViewAdvancedSettings', parentId: 'advancedSettings' }
    { type      : 'separator' }
    { title     : 'customViewFullscreen' }
    { type      : 'separator' }
    { title     : 'Exit',                eventName : 'exit' }
  ]
  fileTypes     : [
    'php', 'pl', 'py', 'jsp', 'asp', 'aspx', 'htm', 'html', 'phtml', 'shtml',
    'sh', 'cgi', 'htaccess', 'fcgi', 'wsgi', 'mvc', 'xml', 'sql', 'rhtml', 'diff',
    'js', 'json', 'coffee', 'css', 'styl', 'sass', 'scss', 'less', 'txt', 'erb'
  ]
