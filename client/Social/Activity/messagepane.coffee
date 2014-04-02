class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.cssClass  = 'message-pane'

    super options, data

    {itemClass} = @getOptions()

    @listController       = new ActivityListController
      startWithLazyLoader : yes
      lazyLoaderOptions   : partial : ''
      scrollView          : no
      wrapper             : yes
      viewOptions         :
        type              : 'message'
        itemClass         : itemClass

    @listView = @listController.getView()

  viewAppended: ->

    @addSubView @listView

    {appManager} = KD.singletons

    appManager.tell 'Activity', 'fetchPublicActivities', {}, (err, items)=>

      log items

      @listController.hideLazyLoader()
      @listController.listActivities items