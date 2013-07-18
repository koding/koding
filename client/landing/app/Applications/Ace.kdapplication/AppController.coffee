class AceAppController extends AppController

  KD.registerAppClass this,
    name          : "Ace"
    multiple      : yes
    hiddenHandle  : no
    openWith      : "lastActive"
    navItem       :
      title       : "Develop"
    route         :
      slug        : "/:name?/Develop/Ace"
      handler     : ({params:{name}, query})->
        router = KD.getSingleton 'router'
        warn "ace handling itself", name, query, arguments
        router.openSection "Ace", name, query
    behavior      : "application"
    menu          : [
      { title     : "Save",                eventName : "save" }
      { title     : "Save As",             eventName : "saveAs" }
      { type      : "separator" }
      { title     : "Find",                eventName : "find" }
      { title     : "Find and Replace",    eventName : "findAndReplace" }
      { type      : "separator" }
      { title     : "Compile and Run",     eventName : "compileAndRun" }
      { type      : "separator" }
      { title     : "Preview",             eventName : "preview" }
      { type      : "separator" }
      { title     : "Advanced Settings",   id        : "advancedSettings" }
      { title     : "customViewAdvancedSettings", parentId: "advancedSettings"}
      { type      : "separator" }
      { title     : "Recently Opened",     id        : "recents"}
      { title     : "customViewRecents",   parentId  : "recents"}
      { title     : "Reopen Latest Files", eventName : "reopen" }
      { type      : "separator" }
      { title     : "Exit",                eventName : "exit" }
    ]
    fileTypes     : [
      "php", "pl", "py", "jsp", "asp", "aspx", "htm", "html", "phtml","shtml",
      "sh", "cgi", "htaccess","fcgi","wsgi","mvc","xml","sql","rhtml", "diff",
      "js","json", "coffee", "css","styl","sass", "scss", "less", "txt"
    ]
    # mimeTypes    : "text"

  constructor: (options = {}, data)->

    options.view = new AceAppView
    options.appInfo =
      name         : "Ace"
      type         : "application"
      cssClass     : "ace"

    super options, data

    @on "AppDidQuit", -> @getView().emit "AceAppDidQuit"


  openFile: (file) ->

   @getView().openFile file
