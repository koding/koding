class AppController extends KDViewController

  bringToFront:(options = {}, view = @getView())->

    @propagateEvent
      KDEventType  : 'ApplicationWantsToBeShown'
      globalEvent  : yes
    ,
      options : options
      data    : view

  initAndBringToFront:(options, callback)->
    @bringToFront()
    callback()
