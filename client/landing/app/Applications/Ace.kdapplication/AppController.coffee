class AceAppController extends AppController

  constructor: (options = {}, data)->
    options.view = new AceAppView

    super options

  bringToFront: ->
    appOptions =
      name         : 'Editor'
      type         : 'application'
      hiddenHandle : no

    view = @getView()
    
    @propagateEvent
      KDEventType: 'ApplicationWantsToBeShown'
      globalEvent: yes
    ,
      options: appOptions,
      data   : view

    view.on 'AceAppViewWantsToClose', =>
      @propagateEvent
        KDEventType : 'ApplicationWantsToClose',
        globalEvent: yes
      ,
        data : view

  openFile: (file) ->
    isAceAppOpen = KD.getSingleton('mainView').mainTabView.getPaneByName 'Editor' #FIXME
    
    @bringToFront()

    @getView().openFile file
