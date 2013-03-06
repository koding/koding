class AppController extends KDViewController

  createContentDisplay:(tag, doShow, callback)->

    [callback, doShow] = [doShow, callback] unless callback
    @showContentDisplay tag, callback

  handleQuery:(query)->

    # log "#{@getOption "name"} handles the query!"
    @ready =>
      # log "#{@getOption "name"} handled the query!"
      @feedController?.handleQuery? query

  setGroup:(group)-> @bringToFront()
