class AppController extends KDViewController

  bringToFront:(options = {}, view = @getView())->
    @propagateEvent
      KDEventType  : 'ApplicationWantsToBeShown'
      globalEvent  : yes
    ,
      options : options
      data    : view

  createContentDisplay:(tag, doShow, callback)->
    [callback, doShow] = [doShow, callback] unless callback
    @showContentDisplay tag, callback

  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query
