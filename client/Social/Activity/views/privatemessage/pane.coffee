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

    options.wrapper     ?= yes
    options.lastToFirst  = yes

    super options, data

    channel = @getData()

    @listPreviousLink = new ReplyPreviousLink
      delegate : @listController
      click    : @bound 'listPreviousReplies'
      linkCopy : 'Show previous replies'
    , channel

    # To keep track of who are the shown participants
    # This way we are preventing to be duplicates
    # on page even if events from backend come more than
    # once.
    @participantMap = {}

    @createParticipantsView()

    @kodingBot = new KodingBot delegate : this

    @listController.getListView().on 'ItemWasAdded', @bound 'messageAdded'
    @listController.getListView().on 'ItemWasRemoved', @bound 'messageRemoved'


  createInputWidget: ->

    channel = @getData()

    @input = new ReplyInputWidget {channel}


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


  setResponseMode: (mode) ->

    if mode is on
      lastQuestion = @listController.getListItems().last

    INTERACTIVE_MODE = mode


  loadMessage: (message) -> @appendMessage message, 0


  hasSameOwner = (a, b) -> a.getData().account._id is b.getData().account._id


  listPreviousReplies: (event) ->

    @listController.showLazyLoader()

    {appManager} = KD.singletons
    first         = @listController.getItemsOrdered().first
    return  unless first

    from         = first.getData().meta.createdAt.toISOString()

    @fetch {from, limit: 10}, (err, items = []) =>
      @listController.hideLazyLoader()

      return KD.showError err  if err

      items.forEach @lazyBound 'loadMessage'


  messageAdded: (item, index) ->

    @scrollDown item
    {data} = item

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
            top     : @participantsView.getY() + 50
            left    : @participantsView.getX() - 150
        , @getData()


  viewAppended: ->

    @addSubView @participantsView
    @addSubView @listPreviousLink
    @addSubView @listController.getView()
    @addSubView @input  if @input
    @populate()

