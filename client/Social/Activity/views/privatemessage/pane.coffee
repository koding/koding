class PrivateMessagePane extends MessagePane

  TEST_MODE        = on
  INTERACTIVE_MODE = off
  lastQuestion     = null
  isFromBot        = (message, callback) ->
    {_id} = message.account
    KD.remote.cacheable 'JAccount', _id, (err, {profile})->
      {nickname} = profile
      callback nickname in ['kodingbot', 'kbot']


  constructor: (options = {}, data) ->

    options.wrapper      ?= yes
    options.lastToFirst   = yes
    options.itemClass   or= PrivateMessageListItemView

    super options, data

    @listPreviousLink = new ReplyPreviousLink
      delegate : @listController
      click    : @bound 'listPreviousReplies'
      linkCopy : 'Show previous replies'
    , data

    # To keep track of who are the shown participants
    # This way we are preventing to be duplicates
    # on page even if events from backend come more than
    # once.
    @participantMap = {}

    @createParticipantsView()
    @createAddParticipantForm()

    @kodingBot = new KodingBot delegate : this

    @listController.getListView().on 'ItemWasAdded', @bound 'messageAdded'
    @listController.getListView().on 'ItemWasRemoved', @bound 'messageRemoved'
    @listController.getListView().on 'EditMessageReset', @input.bound 'focus'

    KD.singleton('windowController').on 'ScrollHappened', @bound 'handleScroll'


  handleScroll: do ->

    previous = 0

    KD.utils.throttle ->
      current = document.body.scrollTop
      @listPreviousReplies()  if current < 20 and current < previous
      previous = current
    , 200


  createInputWidget: ->

    channel = @getData()

    @input = new ReplyInputWidget {channel}

    @input.on 'EditModeRequested', @bound 'editLastMessage'


  editLastMessage: ->

    items = @listController.getItemsOrdered().slice(0).reverse()
    return item.showEditWidget() for item in items when KD.isMyPost item.getData()


  # override this so that it won't
  # have to scroll to the top when
  # a new item is added to list
  # scrollUp: -> return


  parse = (args...) -> args.map (item) -> parseInt item


  # as soon as the enter key down,
  # we create a fake itemview and put
  # it to dom. once the response from server
  # comes back, it will replace the fake one
  # with the real one.
  handleEnter: (value, clientRequestId) ->

    return  unless value

    @applyTestPatterns value  if TEST_MODE
    @applyInteractiveResponse value  if INTERACTIVE_MODE

    super value, clientRequestId
    @input.empty()


  applyTestPatterns: (value) ->

    if value.match /^\/unleashtheloremipsum/
      [_, interval, batchCount] = value.split " "
      [interval, batchCount] = parse interval, batchCount
      PrivateMessageLoadTest.run this, interval, batchCount
    else if value.match /^\/analyzetheloremipsum/
      PrivateMessageLoadTest.analyze this


  applyInteractiveResponse: (value) ->

    if lastQuestion
      message = lastQuestion.getData()
      @kodingBot.process message, value


    @setResponseMode off


  bindChannelEvents: (channel) ->

    return  unless channel

    super channel

    channel
      .on 'AddedToChannel', @bound 'addParticipant'


  addMessage: (message) ->

    return  if message.account._id is KD.whoami()._id

    item = @prependMessage message, @listController.getItemCount()

    isFromBot message, @bound 'setResponseMode'

    return item


  putMessage: (message, index) ->

    @appendMessage message, index or @listController.getItemCount()


  setResponseMode: (mode) ->

    if mode is on
      lastQuestion = @listController.getListItems().last

    INTERACTIVE_MODE = mode


  loadMessage: (message) -> @appendMessage message, 0


  hasSameOwner = (a, b) -> a.getData().account._id is b.getData().account._id


  listPreviousReplies: do ->

    inProgress = false

    (event) ->

      return  if inProgress

      inProgress = true

      {appManager} = KD.singletons
      first         = @listController.getItemsOrdered().first
      return  unless first

      from         = first.getData().createdAt

      @listPreviousLink.updatePartial 'Fetching previous messages...'

      @fetch {from, limit: 10}, (err, items = []) =>
        @listPreviousLink.updatePartial 'Pull or click here to view more'

        return KD.showError err  if err

        items.forEach @lazyBound 'loadMessage'

        inProgress = false


  messageAdded: (item, index) ->

    @scrollDown item
    data         = item.getData()
    listView     = @listController.getView()
    headerHeight = @heads?.getHeight() or 0

    if window.innerHeight - headerHeight < listView.getHeight()
      listView.unsetClass 'padded'

    # TODO: This is a temporary fix,
    # we need to revisit this part.
    # messageAdded & messageRemoved has a race
    # condition problem. ~Umut
    if data.clientRequestId and not data.isFake
      fakeItem = @fakeMessageMap[data.clientRequestId]

      if fakeItem.hasClass 'consequent'
      then item.setClass 'consequent'
      else item.unsetClass 'consequent'

      return

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


  messageRemoved: (item, index) ->

    return  if item.getData().isFake

    {data} = item

    prevSibling = @listController.getListItems()[index-1]
    nextSibling = @listController.getListItems()[index]

    if nextSibling and prevSibling
      if hasSameOwner prevSibling, nextSibling
      then nextSibling.setClass 'consequent'
      else nextSibling.unsetClass 'consequent'
    else if nextSibling
      nextSibling.unsetClass 'consequent'


  appendMessageDeferred: (item) ->
    # Super method defers adding list items to minimize page load
    # congestion. This function is overrides super function to render
    # all conversation messages to be displayed at the same time
    @appendMessage item


  populate: ->

    super =>

      listView = @listController.getView()
      @listPreviousReplies()  if listView.getHeight() <= window.innerHeight


  fetch: (options = {}, callback) ->

    super options, (err, data) =>
      channel = @getData()
      channel.replies = data
      @listPreviousLink.updateView data
      callback err, data


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


  createParticipantsView : ->

    {participantsPreview} = @getData()

    @participantsView = new KDCustomHTMLView
      cssClass    : 'chat-heads'
      partial     : '<span class="description">Chat between</span>'


    @participantsView.addSubView @actionsMenu = new PrivateMessageSettingsView {}, @getData()

    @participantsView.addSubView @heads = new KDCustomHTMLView
      cssClass    : 'heads'

    @addParticipant participant for participant in participantsPreview

    @participantsView.addSubView @newParticipantButton = new KDButtonView
      cssClass    : 'new-participant'
      iconOnly    : yes
      callback    : =>
        @autoCompleteForm.toggleClass 'active'
        @newParticipantButton.toggleClass 'active'
        @autoComplete.getView().setFocus()  if @autoCompleteForm.hasClass 'active'


  createAddParticipantForm: ->

    @autoCompleteForm = new KDFormViewWithFields
      title              : 'START A CHAT WITH:'
      cssClass           : 'new-message-form inline'
      fields             :
        recipient        :
          itemClass      : KDView

    @autoComplete = new KDAutoCompleteController
      name                : 'userController'
      placeholder         : 'Type a username...'
      itemClass           : ActivityAutoCompleteUserItemView
      itemDataPath        : 'profile.nickname'
      outputWrapper       : new KDView cssClass: 'hidden'
      listWrapperCssClass : 'private-message hidden'
      submitValuesAsText  : yes
      dataSource          : @bound 'fetchAccounts'

    @autoCompleteForm.inputs.recipient.addSubView @autoComplete.getView()

    @autoComplete.on 'ItemListChanged', (count) =>
      participant  = @autoComplete.getSelectedItemData()[count - 1]
      options      =
        channelId  : @getData().getId()
        accountIds : [participant.socialApiId]

      {channel} = KD.singleton 'socialapi'
      channel.addParticipants options, (err, result) =>
        if err
          KD.showError err
          @autoComplete.reset()
          return


  fetchAccounts: PrivateMessageForm::fetchAccounts


  viewAppended: ->

    @addSubView @participantsView
    @addSubView @autoCompleteForm
    @addSubView @listPreviousLink
    @addSubView @listController.getView()
    @addSubView @input  if @input
    @populate()


  setFilter: ->


  defaultFilter: 'Most Recent'
