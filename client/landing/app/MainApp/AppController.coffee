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

  createContentDisplay:(tag, doShow, callback)->
    [callback, doShow] = [doShow, callback] unless callback
    @showContentDisplay tag, callback

  handleQuery:(query)-> console.log 'handle query is called', query
