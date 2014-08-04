class PrivateMessagePane extends MessagePane

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

    @messageMap = {}

    @createParticipantsView()

    @input = new ReplyInputWidget {channel}

    @listController.getListView().on 'ItemWasAdded', @bound 'privateMessageAdded'
    @listController.getListView().on 'ItemWasRemoved', @bound 'privateMessageRemoved'


  bindChannelEvents: (channel) ->

    return  unless channel

    super channel

    channel
      .on 'AddedToChannel', @bound 'addParticipant'


  addMessage: (message) ->
    return  if @messageMap[message.id]

    @messageMap[message.id] = yes
    @prependMessage message, @listController.getItemCount()


  loadMessage: (message) -> @appendMessage message, 0


  viewAppended: ->
    @addSubView @participantsView
    @addSubView @listPreviousLink
    @addSubView @listController.getView()
    @addSubView @input  if @input
    @populate()


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
            top     : @getY() + 50
            left    : @getX() - 150
        , @getData()

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

  privateMessageAdded: (item, index) ->
    @scrollDown()
    {data} = item
    @messageMap[data.id] = yes

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
    {data} = item
    delete @messageMap[data.id]

    prevSibling = @listController.getListItems()[index-1]
    nextSibling = @listController.getListItems()[index]

    if nextSibling and prevSibling
      if hasSameOwner prevSibling, nextSibling
      then nextSibling.setClass 'consequent'
      else nextSibling.unsetClass 'consequent'
    else if nextSibling
      nextSibling.unsetClass 'consequent'

  fetch: (options = {}, callback) ->
    options.limit or= 3
    super options, (err, data) =>
      channel = @getData()
      channel.replies = data
      @listPreviousLink.updateView data
      callback err, data
