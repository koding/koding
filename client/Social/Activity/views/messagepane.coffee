class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type        or= ''
    options.cssClass      = "message-pane #{options.type}"
    options.lastToFirst  ?= no
    options.scrollView   ?= yes
    options.itemClass   or= ActivityListItemView

    super options, data

    @lastScrollTops =
      window        : 0
      parent        : 0
      self          : 0
      body          : 0

    { itemClass, lastToFirst, wrapper, channelId
      scrollView, noItemFoundWidget, startWithLazyLoader
    } = @getOptions()

    {typeConstant} = @getData()

    @listController = new ActivityListController {
      type          : typeConstant
      viewOptions   :
        itemOptions : {channelId}
      wrapper
      itemClass
      lastToFirst
      scrollView
      noItemFoundWidget
      startWithLazyLoader
    }

    @listController.getView().setClass 'padded'

    @createChannelTitle()
    @createInputWidget()
    @createFilterLinks()
    @bindInputEvents()

    @submitIsPending = no

    @fakeMessageMap = {}

    @setFilter @getDefaultFilter()

    {socialapi} = KD.singletons
    @once 'ChannelReady', @bound 'bindChannelEvents'
    socialapi.onChannelReady data, @lazyBound 'emit', 'ChannelReady'

    if typeConstant in ['group', 'topic', 'announcement']
      @on 'LazyLoadThresholdReached', @bound 'lazyLoad'

    KD.singletons.windowController.addFocusListener @bound 'handleFocus'


  bindInputEvents: ->

    return  unless @input

    @input
      .on 'SubmitStarted',    => @submitIsPending = yes
      .on 'SubmitStarted',    @bound 'handleEnter'
      .on 'SubmitSucceeded',  @bound 'replaceFakeItemView'
      .on 'SubmitSucceeded',  => KD.utils.defer => @submitIsPending = no
      .on 'SubmitFailed',     @bound 'messageSubmitFailed'

  whenSubmitted: ->
    new Promise (resolve) =>
      unless @submitIsPending
        resolve()
      else
        @input.once 'SubmitSucceeded', -> resolve()


  replaceFakeItemView: (message) ->

    @putMessage message, @removeFakeMessage message.clientRequestId


  removeFakeMessage: (identifier) ->

    return  unless item = @fakeMessageMap[identifier]

    index = @listController.getListView().getItemIndex item

    @listController.removeItem item

    return index


  handleEnter: (value, clientRequestId) ->

    return  unless value

    @input.reset yes

    switch @currentFilter
      when 'Most Liked' then @setFilter 'Most Recent'
      else @createFakeItemView value, clientRequestId


  putMessage: (message, index = 0) ->
    @listController.addItem message, index

  createFakeItemView: (value, clientRequestId) ->

    fakeData = KD.utils.generateDummyMessage value

    item = @putMessage fakeData

    # save it to a map so that we have a reference
    # to it to be deleted.
    @fakeMessageMap[clientRequestId] = item

    @scrollDown item


  messageSubmitFailed: (err, clientRequestId) ->
    view = @fakeMessageMap[clientRequestId]
    view.showResend()
    view.on 'SubmitSucceeded', (message) =>
      message.clientRequestId = clientRequestId
      @replaceFakeItemView message


  handleFocus: (focused) -> @glance()  if focused and @active


  putNewMessageIndicator: ->


  isPageAtBottom: ->

    {innerHeight, scrollY} = window
    {scrollHeight} = document.body

    scrollY + innerHeight >= scrollHeight


  scrollDown: ->


  scrollUp: ->

    return  unless @active

    window.scrollTo 0, 0


  setScrollTops: ->

    super

    @lastScrollTops.window = window.scrollY


  applyScrollTops: ->

    super

    KD.utils.defer =>
      window.scrollTo 0, @lastScrollTops.window


  createChannelTitle: ->

    type = @getOption 'type'

    if type is 'privatemessage' or type is 'post' then return

    {name, isParticipant, typeConstant} = @getData()

    @channelTitleView = new KDCustomHTMLView
      partial    : "##{name}"
      cssClass   : "channel-title #{if isParticipant then 'participant' else ''}"
      attributes :
        testpath : 'channel-title'

    if typeConstant not in ['group', 'announcement']
      @channelTitleView.addSubView new TopicFollowButton null, @getData()

  createInputWidget: (placeholder) ->

    return  if @getOption("type") is 'post'

    channel = @getData()
    {socialapi} = KD.singletons

    @input = new ActivityInputWidget { channel, placeholder }


  createFilterLinks: ->

    type = @getOption 'type'

    if type is 'privatemessage' or type is 'post' then return

    filters = ['Most Liked', 'Most Recent']

    {socialapi} = KD.singletons
    # remove the first item from filters
    filters.shift() if socialapi.isAnnouncementItem @getData().id

    @filterLinks or= new FilterLinksView
      filters: filters
      default: filters[0]

    @filterLinks.on 'FilterSelected', (filter) =>
      @listController.removeAllItems()
      @listController.showLazyLoader()
      @setFilter filter


  bindChannelEvents: (channel) ->

    return  unless channel

    channel
      .on 'MessageAdded',   @bound 'realtimeMessageArrived'
      .on 'MessageRemoved', @bound 'removeMessage'


  realtimeMessageArrived: (message) ->

    return  if @currentFilter is 'Most Liked' and not KD.isMyPost message

    {lastToFirst}  = @getOptions()
    index = if lastToFirst then @listController.getItemCount() else 0
    @prependMessage message, index


  loadMessage: (message) ->

    {lastToFirst} = @getOptions()
    index = if lastToFirst then 0 else @listController.getItemCount()
    @appendMessage message, index


  appendMessage: (message, index) -> @listController.addItem message, index


  prependMessage: (message, index, callback = noop) ->

    KD.getMessageOwner message, (err, owner) =>
      return callback err  if err
      return callback() if KD.filterTrollActivity owner
      item = @listController.addItem message, index
      callback null, item


  removeMessage: (message) ->

    listItems = @listController.getListItems()

    [item] = listItems.filter (item) -> item.getData().getId() is message.getId()

    if item?
      item.once 'HideAnimationFinished', =>
        @listController.removeItem item
        @listController.showNoItemWidget() if @listController.getListItems().length is 0

      item.hide()


  viewAppended: ->

    @addSubView @channelTitleView  if @channelTitleView
    @addSubView @input             if @input
    @addSubView @filterLinks       if @filterLinks
    @addSubView @listController.getView()


  show: ->

    super

    KD.utils.wait 1000, @bound 'glance'



  glance: ->

    {socialapi, appManager}  = KD.singletons
    {id, typeConstant, name} = @getData()

    app  = appManager.get 'Activity'
    item = app.getView().sidebar.selectedItem

    return  unless item?.count
    # no need to send updatelastSeenTime or glance when checking publicfeeds
    return  if name in ['public', 'announcement']

    if typeConstant is 'post'
    then socialapi.channel.glancePinnedPost   messageId : id, @bound 'glanced'
    else socialapi.channel.updateLastSeenTime channelId : id, @bound 'glanced'


  glanced: ->

    @separator?.destroy()
    @separator = null


  focus: ->


  populate: (callback = noop) ->

    filter = @currentFilter

    @fetch null, (err, items = []) =>

      return KD.showError err  if err

      return  if @currentFilter isnt filter

      @listController.hideLazyLoader()
      items.forEach (item, i) =>
        @addMessageDeferred item, i, items.length

      KD.utils.defer @bound 'focus'

      callback()


  addMessageDeferred: (item, i, total) ->

    KD.utils.defer =>
      @appendMessage item
      if i is total - 1
        KD.utils.wait 50, => @emit 'ListPopulated'



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

    @whenSubmitted().then ->
      # if it is a post it means we already have the data
      if type is 'post'
      then KD.utils.defer -> callback null, [data]
      else appManager.tell 'Activity', 'fetch', options, callback

  lazyLoad: do ->

    loading = no

    ->

      return  if loading

      @listController.showLazyLoader()

      {appManager} = KD.singletons
      last         = @listController.getItemsOrdered().last

      return @listController.hideLazyLoader()  unless last

      loading = yes

      if @currentFilter is 'Most Liked'
        from = null
        skip = @listController.getItemsOrdered().length
      else
        from = last.getData().createdAt

      @fetch {from, skip}, (err, items=[])=>
        loading = no
        @listController.hideLazyLoader()

        return KD.showError err  if err

        items.forEach @lazyBound 'loadMessage'


  refresh: ->

    window.scrollTo 0, 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()


  setFilter: (filter) ->

    return  if @currentFilter is filter

    @filterLinks.selectFilter @currentFilter
    @populate()


  getDefaultFilter:->

    {socialapi} = KD.singletons

    if socialapi.isAnnouncementItem @getData().id
    then 'Most Recent'
    else 'Most Liked'
