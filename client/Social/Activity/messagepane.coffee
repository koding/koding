class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"

    super options, data

    {itemClass, type} = @getOptions()

    @listController = new ActivityListController
      itemClass     : itemClass
      lastToFirst   : yes  if type is 'messaging'

    @listView = @listController.getView()
    @input    = new ActivityInputWidget


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