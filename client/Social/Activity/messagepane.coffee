class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.cssClass  = 'message-pane'

    super options, data

    {itemClass} = @getOptions()

    @listController = new ActivityListController
      itemClass     : itemClass

    @listView = @listController.getView()


  viewAppended: ->

    @addSubView @listView
    @populate()


  populate: ->

    @fetch (err, items) =>

      @listController.hideLazyLoader()
      @listController.listActivities items


  fetch: (callback)->

    {appManager} = KD.singletons
    appManager.tell 'Activity', 'fetchPublicActivities', {}, callback


  refresh: ->

    document.body.scrollTop            = 0
    document.documentElement.scrollTop = 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()