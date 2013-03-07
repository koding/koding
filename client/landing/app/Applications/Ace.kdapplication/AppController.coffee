class AceAppController extends AppController

  KD.registerAppClass @,
    name         : "Ace"
    multiple     : yes
    hiddenHandle : no
    openWith     : "lastActive"
    route        : "Develop"
    behavior     : "application"
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
