class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"

    super options, data

    {itemClass, type} = @getOptions()

    @listController = new ActivityListController {itemClass}
    @createInputWidget()

    @bindChannelEvents()

    @on 'LazyLoadThresholdReached', @bound 'lazyLoad'  if data.typeConstant in ['group', 'topic']


  createInputWidget: ->

    return  if @getOption("type") in ['post', 'privatemessage']

    channel = @getData()

    @input = new ActivityInputWidget {channel}


  bindChannelEvents: ->

    {socialapi} = KD.singletons
    socialapi.onChannelReady @getData(), (channel) =>

      return  unless channel

      channel
        .on 'MessageAdded',   @bound 'prependMessage'
        .on 'MessageRemoved', @bound 'removeMessage'


  appendMessage: (message) -> @listController.addItem message, @listController.getItemCount()

  prependMessage: (message) -> @listController.addItem message, 0

  removeMessage: (message) -> @listController.removeItem message


  viewAppended: ->

    @addSubView @input  if @input
    @addSubView @listController.getView()
    @populate()


  show: ->

    super

    KD.utils.wait 1000, @bound 'glance'


  glance: ->

    data = @getData()
    {id, typeConstant} = data
    {windowController, socialapi} = KD.singletons

    return  unless windowController.focused

    item = @getDelegate().parent.sidebar.selectedItem

    return  unless item.count

    if typeConstant is 'message'
    then socialapi.channel.glancePinnedPost messageId : id, log
    else socialapi.channel.updateLastSeenTime channelId : id, log






  populate: ->

    @fetch null, (err, items = []) =>

      return KD.showError err  if err

      console.time('populate')
      @listController.hideLazyLoader()
      @listController.instantiateListItems items
      console.timeEnd('populate')


  fetch: (options = {}, callback)->

    {
      name
      type
      channelId
    }            = @getOptions()
    data         = @getData()
    {appManager} = KD.singletons

    options.name      = name
    options.type      = type
    options.channelId = channelId

    # if it is a post it means we already have the data
    if type is 'post'
    then KD.utils.defer -> callback null, [data]
    else appManager.tell 'Activity', 'fetch', options, callback


  lazyLoad: ->

    {appManager} = KD.singletons
    last         = @listController.getItemsOrdered().last
    from         = last.getData().meta.createdAt.toISOString()

    @fetch {from}, (err, items = []) =>

      return KD.showError err  if err

      items.forEach @lazyBound 'appendMessage'


  refresh: ->

    document.body.scrollTop            = 0
    document.documentElement.scrollTop = 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()

