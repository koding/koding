class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.cssClass  = 'message-pane'

    super options, data

    {itemClass} = @getOptions()

    @listController = new ActivityListController
      itemClass     : itemClass or ActivityListItemView

    @listView = @listController.getView()

  viewAppended: ->

    @addSubView @listView

    {appManager} = KD.singletons

    appManager.tell 'Activity', 'fetchPublicActivities', {}, (err, items)=>

      @listController.hideLazyLoader()
      @listController.listActivities items