class KDViewController extends KDController

  constructor:->

    super

    @setView @getOptions().view if @getOptions().view?

  bringToFront:(options = {}, view = @getView())->

    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown'
      globalEvent : yes
    ,
      options     : options
      data        : view

  initAndBringToFront:(options, callback)->

    @bringToFront()
    callback()

  loadView:(mainView)->

  getView:()-> @mainView

  setView:(aViewInstance)->

    @mainView = aViewInstance
    cb = @loadView.bind(@, aViewInstance)
    if aViewInstance.isViewReady() then do cb
    else
      aViewInstance.on 'viewAppended', cb
      aViewInstance.on 'KDObjectWillBeDestroyed', => @destroy()