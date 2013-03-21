class AppController extends KDViewController

  createContentDisplay:(models, callback)->
    warn "You need to override #createContentDisplay - #{@constructor.name}"

  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query
