class AppController extends KDViewController

  bringToFront:(view = @getView(), options = @getOption "appInfo")->

    @emit 'ApplicationWantsToBeShown', @, view, options

  createContentDisplay:(tag, doShow, callback)->

    [callback, doShow] = [doShow, callback] unless callback
    @showContentDisplay tag, callback

  handleQuery:(query)->

    # log "#{@getOption "name"} handles the query!"
    @ready =>
      # log "#{@getOption "name"} handled the query!"
      @feedController?.handleQuery? query

  setGroup:(group)-> @bringToFront()
