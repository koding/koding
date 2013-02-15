class AppController extends KDViewController

  bringToFront:(options = {}, view = @getView())->

    @emit 'ApplicationWantsToBeShown', @, view, options

  createContentDisplay:(tag, doShow, callback)->

    [callback, doShow] = [doShow, callback] unless callback
    @showContentDisplay tag, callback

  handleQuery:(query)->

    @ready => @feedController?.handleQuery? query

  setGroup:(group)-> @bringToFront()
