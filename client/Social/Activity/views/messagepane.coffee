class MessagePane extends KDTabPaneView

  TEST_MODE  = on

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"
    options.wrapper     ?= yes
    options.lastToFirst ?= no

    super options, data

    @TEST_CLASS = ActivityLoadTest

    @lastScrollTops =
      window        : 0
      parent        : 0
      self          : 0
      body          : 0

    {itemClass, type, lastToFirst, wrapper, channelId} = @getOptions()
    {typeConstant} = @getData()
    viewOptions = {itemOptions: {channelId}}

    @listController = new ActivityListController { wrapper, itemClass, type: typeConstant, viewOptions, lastToFirst}

    @createChannelTitle()
    @createInputWidget()
    @createFilterLinks()
    @bindInputEvents()

    @fakeMessageMap = {}

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

    @applyTestPatterns value  if TEST_MODE is on

    @input.reset yes
    @createFakeItemView value, clientRequestId

  parse = (args...) -> args.map (item) -> parseInt item

  applyTestPatterns: (value) ->

    if value.match /^\/unleashtheloremipsum/
      [_, interval, batchCount] = value.split " "
      [interval, batchCount] = parse interval, batchCount
      @TEST_CLASS.run this, interval, batchCount
    else if value.match /^\/analyzetheloremipsum/
      @TEST_CLASS.analyze this


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

    @filterLinks = new FilterLinksView {},
      'Most Recent'  :
        active      : yes


  bindChannelEvents: (channel) ->

    return  unless channel

    channel
      .on 'MessageAdded',   @bound 'addMessage'
      .on 'MessageRemoved', @bound 'removeMessage'


  addMessage: (message) ->

    return  if message.account._id is KD.whoami()._id

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
    @populate()


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


  populate: ->

    @fetch null, (err, items = []) =>

      return KD.showError err  if err

      @listController.hideLazyLoader()
      items.forEach (item) => KD.utils.defer => @appendMessage item

      KD.utils.defer @bound 'focus'


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

    @listController.showLazyLoader()

    {appManager} = KD.singletons
    last         = @listController.getItemsOrdered().last

    return  unless last

    from         = last.getData().createdAt

    @fetch {from}, (err, items = []) =>
      @listController.hideLazyLoader()

      return KD.showError err  if err

      items.forEach @lazyBound 'loadMessage'


  refresh: ->

    document.body.scrollTop            = 0
    document.documentElement.scrollTop = 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()

