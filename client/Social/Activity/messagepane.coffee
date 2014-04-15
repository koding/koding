class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"

    super options, data

    channel           = @getData()
    {itemClass, type} = @getOptions()

    @listController = new ActivityListController
      itemClass     : itemClass
      lastToFirst   : yes  if type is 'message'

    @listView = @listController.getView()
    @input    = new ActivityInputWidget {channel}


  viewAppended: ->

    @addSubView @input
    @addSubView @listView
    @populate()


  populate: ->

    @fetch (err, items) =>

      console.time('populate')
      @listController.hideLazyLoader()
      @listController.listActivities items
      console.timeEnd('populate')


  fetch: (callback)->

    {appManager} = KD.singletons
    appManager.tell 'Activity', 'fetchPublicActivities', {}, callback


  refresh: ->

    document.body.scrollTop            = 0
    document.documentElement.scrollTop = 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()