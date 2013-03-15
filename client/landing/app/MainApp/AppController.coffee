class AppController extends KDViewController

  createContentDisplay:(models, doShow, callback)->

    [callback, doShow] = [doShow, callback] unless callback
    @showContentDisplay models[0], callback

  handleQuery:(query)->

    # log "#{@getOption "name"} handles the query!"
    @ready =>
      # log "#{@getOption "name"} handled the query!"
      @feedController?.handleQuery? query

#  setGroup:(group)-> @bringToFront()
