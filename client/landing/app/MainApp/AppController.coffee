class AppController extends KDViewController

  createContentDisplay:(models, doShow, callback)->
    warn "You need to override #createContentDisplay"

  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query
