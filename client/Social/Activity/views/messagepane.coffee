class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"

    super options, data

    @lastScrollTops =
      window        : 0
      parent        : 0
      self          : 0
      body          : 0

    {itemClass, type} = @getOptions()
    {typeConstant}    = @getData()

    # To keep track of who are the shown participants
    # This way we are preventing to be duplicates
    # on page even if events from backend come more than
    # once.
    @participantMap = {}

    {channelId} = options
    viewOptions = {itemOptions: {channelId}}
    @lastToFirst = no
    if typeConstant is 'privatemessage'
      @createParticipantsView()
      @lastToFirst = yes
    @listController = new ActivityListController { wrapper: yes, itemClass, type: typeConstant, viewOptions, @lastToFirst}


    @createInputWidget()
    @bindChannelEvents()

    @on 'LazyLoadThresholdReached', @bound 'lazyLoad'  if typeConstant in ['group', 'topic']

    {windowController} = KD.singletons
    windowController.addFocusListener (focused) =>

      @glance()  if focused and @active

    switch typeConstant
      when 'post'
        @listController.getListView().once 'ItemWasAdded', (item) =>
          listView = @listController.getListItems().first.commentBox.controller.getListView()
          listView.on 'ItemWasAdded', @bound 'scrollDown'
      when 'privatemessage'
        @listController.getListView().on 'ItemWasAdded', @bound 'privateMessageAdded'
        @listController.getListView().on 'ItemWasRemoved', @bound 'privateMessageRemoved'
      else
        @listController.getListView().on 'ItemWasAdded', @bound 'scrollUp'


  hasSameOwner = (a, b) -> a.getData().account._id is b.getData().account._id

  privateMessageAdded: (item, index) ->
    prevSibling = @listController.getListItems()[index-1]
    nextSibling = @listController.getListItems()[index+1]

    if prevSibling
      if hasSameOwner item, prevSibling
      then item.setClass 'consequent'
      else item.unsetClass 'consequent'

    if nextSibling
      if hasSameOwner item, nextSibling
      then nextSibling.setClass 'consequent'
      else nextSibling.unsetClass 'consequent'


  privateMessageRemoved: (item, index) ->

    prevSibling = @listController.getListItems()[index-1]
    nextSibling = @listController.getListItems()[index]

    if nextSibling and prevSibling
      if hasSameOwner prevSibling, nextSibling
      then nextSibling.setClass 'consequent'
      else nextSibling.unsetClass 'consequent'
    else if nextSibling
      nextSibling.unsetClass 'consequent'


  scrollDown: (item) ->

    return  unless @active

    listView = @listController.getListItems().first.commentBox.controller.getListView()
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


  createParticipantsView : ->

    {participantsPreview} = @getData()

    @participantsView = new KDCustomHTMLView
      cssClass    : 'chat-heads'
      partial     : '<span class="description">Private conversation between</span>'

    @participantsView.addSubView @heads = new KDCustomHTMLView
      cssClass    : 'heads'

    @addParticipant participant for participant in participantsPreview

    @participantsView.addSubView @newParticipantButton = new KDButtonView
      cssClass    : 'new-participant'
      iconOnly    : yes
      callback    : =>
        new PrivateMessageRecipientModal
          blacklist : participantsPreview.map (item) -> item._id
          position  :
            top     : @getY() + 50
            left    : @getX() - 150
        , @getData()


  addParticipant: (participant) ->

    return  unless participant
    return  if @participantMap[participant._id]

    participant.id = participant._id

    @heads.addSubView new AvatarView
      size      :
        width   : 30
        height  : 30
      origin    : participant

    @participantMap[participant._id] = yes


  createInputWidget: ->

    return  if @getOption("type") in ['post', 'privatemessage']

    channel = @getData()

    @input = new ActivityInputWidget {channel}


  bindChannelEvents: ->

    {socialapi} = KD.singletons
    socialapi.onChannelReady @getData(), (channel) =>

      return  unless channel

      channel
        .on 'MessageAdded',   @bound 'addMessage'
        .on 'MessageRemoved', @bound 'removeMessage'
        .on 'AddedToChannel', @bound 'addParticipant'

  addMessage: (message) ->
    index = if @lastToFirst then @listController.getItemCount() else 0
    @prependMessage message, index

  loadMessage: (message) ->
    index = if @lastToFirst then 0 else @listController.getItemCount()
    @appendMessage message, index

  appendMessage: (message, index) -> @listController.addItem message, index

  prependMessage: (message, index) ->
    KD.getMessageOwner message, (err, owner) =>
      return error err  if err
      return if KD.filterTrollActivity owner
      @listController.addItem message, index

  removeMessage: (message) -> @listController.removeItem null, message


  viewAppended: ->

    @addSubView @participantsView if @participantsView
    @addSubView @input  if @input
    @addSubView @listController.getView()
    @populate()


  show: ->

    super

    KD.utils.wait 1000, @bound 'glance'
    KD.utils.defer @bound 'focus'


  glance: ->

    data = @getData()
    {id, typeConstant} = data
    {socialapi, appManager} = KD.singletons

    app  = appManager.get 'Activity'
    item = app.getView().sidebar.selectedItem

    return  unless item?.count
    # no need to send updatelastSeenTime or glance
    # when checking publicfeeds
    return  if typeConstant is 'group'

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
      @listController.getListItems().first?.commentBox.inputForm.input.setFocus()


  populate: ->

    @fetch null, (err, items = []) =>

      return KD.showError err  if err

      console.time('populate')
      @listController.hideLazyLoader()
      @listController.instantiateListItems items
      console.timeEnd('populate')

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

    from         = last.getData().meta.createdAt.toISOString()

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

