# this is necessary for ace dependencies, can be moved to another file
# but SHALL NOT BE REMOVED~!
require.config baseUrl: "/js", waitSeconds:30

class AceAppController extends AppController

  # canCompile = (view)->
  #   ace      = view.getActiveAceView()
  #   manifest = KodingAppsController.getManifestFromPath ace.getData().path
  #   return if manifest then yes else no

  KD.registerAppClass this,
    name          : "Ace"
    multiple      : yes
    hiddenHandle  : no
    openWith      : "lastActive"
    navItem       :
      title       : "Editor"
      path        : "/Ace"
      order       : 42
    route         :
      slug        : "/:name?/Ace"
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
      { title     : "Goto line",           eventName : "gotoLine" }
      { type      : "separator" }
      # { title     : "Compile and Run",     eventName : "compileAndRun", condition: canCompile}
      # { type      : "separator",                                        condition: canCompile}
      { title     : "Preview",             eventName : "preview" }
      { type      : "separator" }
      { title     : "Advanced Settings",   id        : "advancedSettings" }
      { title     : "customViewAdvancedSettings", parentId: "advancedSettings"}
      { type      : "separator" }
      { title     : "Recently Opened",     id        : "recents"}
      { title     : "customViewRecents",   parentId  : "recents"}
      { title     : "Reopen Latest Files", eventName : "reopen" }
      { type      : "separator" }
      { title     : "customViewFullscreen" }
      { type      : "separator" }
      { title     : "Exit",                eventName : "exit" }
    ]
    fileTypes     : [
      "php", "pl", "py", "jsp", "asp", "aspx", "htm", "html", "phtml","shtml",
      "sh", "cgi", "htaccess","fcgi","wsgi","mvc","xml","sql","rhtml", "diff",
      "js","json", "coffee", "css","styl","sass", "scss", "less", "txt", "erb"
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
