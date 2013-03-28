class AppController extends KDViewController

  constructor:->

    super

    @appStorage = new AppStorage @getOption("name"), "1.0"

  createContentDisplay:(models, callback)->
    warn "You need to override #createContentDisplay - #{@constructor.name}"

  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query
