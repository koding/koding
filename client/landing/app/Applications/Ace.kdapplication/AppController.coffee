class AceAppController extends AppController

  KD.registerAppClass @,
    name     : "Ace"
    multiple : yes
    # openWith : "last" # "confirm"

  constructor: (options = {}, data)->

    options.view = new AceAppView
    options.appInfo =
      name         : "Ace"
      hiddenHandle : no
      type         : "application"
      cssClass     : "ace"

    super options, data



  #openFile: (file) ->
  #  isAceAppOpen = KD.getSingleton('mainView').mainTabView.getPaneByName 'Editor' #FIXME
  #
  #  @bringToFront()

  #  @getView().openFile file
