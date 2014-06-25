# this is necessary for ace dependencies, can be moved to another file
# but SHALL NOT BE REMOVED~!
requirejs.config baseUrl: "/a/js", waitSeconds:30

class AceAppController extends AppController

  KD.registerAppClass this,
    name          : "Ace"
    multiple      : yes
    hiddenHandle  : no
    openWith      : "lastActive"
    behavior      : "application"
    preCondition  :
      condition   : (options, cb)-> cb KD.isLoggedIn() or KD._isLoggedIn
      failure     : (options, cb)->
        KD.singletons.appManager.open 'Ace', conditionPassed : yes
        KD.showEnforceLoginModal()
    menu          : [
      { title     : "Save",                eventName : "save" }
      { title     : "Save as...",          eventName : "saveAs" }
      { title     : "Save All",            eventName : "saveAll" }
      { type      : "separator" }
      { title     : "Find",                eventName : "find" }
      { title     : "Find and replace...", eventName : "findAndReplace" }
      { title     : "Go to line",          eventName : "gotoLine" }
      { type      : "separator" }
      { title     : "Preview",             eventName : "preview" }
      { type      : "separator" }
      { title     : "Key Bindings",        eventName : "keyBindings" }
      { type      : "separator" }
      { title     : "Advanced settings",   id        : "advancedSettings" }
      { title     : "customViewAdvancedSettings", parentId: "advancedSettings"}
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
