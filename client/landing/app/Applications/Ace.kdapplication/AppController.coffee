class AceAppController extends AppController

  KD.registerAppClass @,
    name     : "Ace"
    multiple : yes

  constructor: (options = {}, data)->
    options.view = new AceAppView

    super options


  #openFile: (file) ->
  #  isAceAppOpen = KD.getSingleton('mainView').mainTabView.getPaneByName 'Editor' #FIXME
  #  
  #  @bringToFront()

  #  @getView().openFile file
