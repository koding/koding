class AppController extends KDViewController

  constructor:->

    super

    {name, version} = @getOptions()
    @appStorage = \
      KD.singletons.appStorageController.storage name, version or "1.0"

  createContentDisplay:(models, callback)->
    warn "You need to override #createContentDisplay - #{@constructor.name}"

  handleQuery:(query)->
    @ready => @feedController?.handleQuery? query
