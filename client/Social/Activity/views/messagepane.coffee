class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"
    options.wrapper     ?= yes
    options.lastToFirst ?= no

    super options, data

    @lastScrollTops =
      window        : 0
      parent        : 0
      self          : 0
      body          : 0

    {itemClass, type, lastToFirst, wrapper, channelId} = @getOptions()
    {typeConstant} = @getData()

    @listController = new ActivityListController {
      type          : typeConstant
      viewOptions   :
        itemOptions : {channelId}
      wrapper
      itemClass
      lastToFirst
    }

    @listController.getView().setClass 'padded'

    @createChannelTitle()
    @createInputWidget()
    @createFilterLinks()
    @bindInputEvents()

    @fakeMessageMap = {}

    @setFilter @defaultFilter

    {socialapi} = KD.singletons
    @once 'ChannelReady', @bound 'bindChannelEvents'
    socialapi.onChannelReady data, @lazyBound 'emit', 'ChannelReady'

    if typeConstant in ['group', 'topic']
      @on 'LazyLoadThresholdReached', @bound 'lazyLoad'

    KD.singletons.windowController.addFocusListener @bound 'handleFocus'

    switch typeConstant
      when 'post'
        @listController.getListView().once 'ItemWasAdded', (item) =>
          listView = @listController.getListItems().first.commentBox.controller.getListView()
          listView.on 'ItemWasAdded', @bound 'scrollDown'
      when 'privatemessage'
        @listController.getListView().on 'ItemWasAdded', @bound 'scrollDown'
      when 'group'
      else
        @listController.getListView().on 'ItemWasAdded', @bound 'scrollUp'


  bindInputEvents: ->

    return  unless @input

    @input
      .on 'SubmitStarted',   @bound 'handleEnter'
      .on 'SubmitSucceeded', @bound 'replaceFakeItemView'
      .on 'SubmitFailed',    @bound 'messageSubmitFailed'


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


  putMessage: (message, index = 0) -> @appendMessage message, index


  createFakeItemView: (value, clientRequestId) ->

    fakeData = KD.utils.generateDummyMessage value

    item = @putMessage fakeData

    # save it to a map so that we have a reference
    # to it to be deleted.
    @fakeMessageMap[clientRequestId] = item


  messageSubmitFailed: (err, clientRequestId) ->
    view = @fakeMessageMap[clientRequestId]
    view.showResend()
    view.on 'SubmitSucceeded', (message) =>
      message.clientRequestId = clientRequestId
      @replaceFakeItemView message


  handleFocus: (focused) -> @glance()  if focused and @active


  scrollDown: (item) ->

    return  unless @active

    {typeConstant} = @getData()

    if item.getDelegate().addSubView
      listView = item.getDelegate()
    else
      listView = item.getDelegate().getListView()

    unless @separator
      @separator = new KDView cssClass : 'new-messages'
      listView.addSubView @separator

    return  unless item is listView.items.last

    KD.utils.defer -> window.scrollTo 0, document.body.scrollHeight


  scrollUp: ->

    return  unless @active

    window.scrollTo 0, 0


  setScrollTops: ->

    super

    @lastScrollTops.window = window.scrollTop or 0
    @lastScrollTops.body   = document.body.scrollTop


  applyScrollTops: ->

    super

    KD.utils.defer =>
      window.scrollTo 0, @lastScrollTops.window
      document.body.scrollTop = @lastScrollTops.body


  createChannelTitle: ->

    type = @getOption 'type'

    if type is 'privatemessage' or type is 'post' then return

    {name, isParticipant} = @getData()

    @channelTitleView = new KDCustomHTMLView
      partial   : "##{name}"
      cssClass  : "channel-title #{if isParticipant then 'participant' else ''}"

    unless name is 'public'
      @channelTitleView.addSubView new TopicFollowButton null, @getData()


  createInputWidget: ->

    return  if @getOption("type") is 'post'

    channel = @getData()

    @input = new ActivityInputWidget {channel}


  createFilterLinks: ->

    type = @getOption 'type'

    if type is 'privatemessage' or type is 'post' then return

    @filterLinks or= new FilterLinksView
      filters: ['Most Liked', 'Most Recent']
      default: 'Most Liked'

    @filterLinks.on 'FilterSelected', (filter) =>
      @listController.removeAllItems()
      @listController.showLazyLoader()
      @setFilter filter


  bindChannelEvents: (channel) ->

    return  unless channel

    channel
      .on 'MessageAdded',   @bound 'addMessage'
      .on 'MessageRemoved', @bound 'removeMessage'


  addMessage: (message) ->

    return  if KD.isMyPost message
    return  if @currentFilter is 'Most Liked' and not KD.isMyPost message

    {lastToFirst} = @getOptions()
    index = if lastToFirst then @listController.getItemCount() else 0
    @prependMessage message, index


  loadMessage: (message) ->

    {lastToFirst} = @getOptions()
    index = if lastToFirst then 0 else @listController.getItemCount()
    @appendMessage message, index


  appendMessage: (message, index) -> @listController.addItem message, index


  prependMessage: (message, index) ->
    KD.getMessageOwner message, (err, owner) =>
      return error err  if err
      return if KD.filterTrollActivity owner
      @listController.addItem message, index

  removeMessage: (message) -> @listController.removeItem null, message


  viewAppended: ->

    @addSubView @channelTitleView  if @channelTitleView
    @addSubView @input             if @input
    @addSubView @filterLinks       if @filterLinks
    @addSubView @listController.getView()


  show: ->

    super

    KD.utils.wait 1000, @bound 'glance'
    KD.utils.defer @bound 'focus'


  glance: ->

    {socialapi, appManager}  = KD.singletons
    {id, typeConstant, name} = @getData()

    app  = appManager.get 'Activity'
    item = app.getView().sidebar.selectedItem

    return  unless item?.count
    # no need to send updatelastSeenTime or glance when checking publicfeeds
    return  if name is 'public'

    if typeConstant is 'post'
    then socialapi.channel.glancePinnedPost   messageId : id, @bound 'glanced'
    else socialapi.channel.updateLastSeenTime channelId : id, @bound 'glanced'


  glanced: ->

    @separator?.destroy()
    @separator = null


  focus: ->

    if @input
      @input.focus()
    else
      @listController.getListItems().first?.commentBox.input.focus()


  populate: (callback = noop) ->

    @fetch null, (err, items = []) =>

      return KD.showError err  if err

      @listController.hideLazyLoader()
      items.forEach @bound 'appendMessageDeferred'

      KD.utils.defer @bound 'focus'

      callback()


  appendMessageDeferred: (item) -> KD.utils.defer @lazyBound 'appendMessage', item


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
    options.mostLiked = yes  if @currentFilter is 'Most Liked'

    # if it is a post it means we already have the data
    if type is 'post'
    then KD.utils.defer -> callback null, [data]
    else appManager.tell 'Activity', 'fetch', options, callback

  lazyLoad: ->

    @listController.showLazyLoader()

    {appManager} = KD.singletons
    last         = @listController.getItemsOrdered().last

    return @listController.hideLazyLoader()  unless last

    if @currentFilter is 'Most Liked'
      from = null
      skip = @listController.getItemsOrdered().length
    else
      from = last.getData().createdAt

    @fetch {from, skip}, (err, items=[])=>
      @listController.hideLazyLoader()

      return KD.showError err  if err

      items.forEach @lazyBound 'loadMessage'


  refresh: ->

    document.body.scrollTop            = 0
    document.documentElement.scrollTop = 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()


  setFilter: (@currentFilter) ->

    @filterLinks.selectFilter @currentFilter
    @populate()


  defaultFilter: 'Most Liked'
