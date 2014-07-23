class PrivateMessagePane extends MessagePane

  constructor: (options = {}, data) ->

    options.wrapper     ?= yes
    options.lastToFirst ?= yes


    super options, data

    # @listPreviousLink.destroy()
    # @listPreviousLink = new CommentListPreviousLink
    #   delegate : @controller
    #   # click    : @bound 'listPreviousReplies'
    #   linkCopy : 'Show previous replies'
    # , data

    # To keep track of who are the shown participants
    # This way we are preventing to be duplicates
    # on page even if events from backend come more than
    # once.
    @participantMap = {}

    @createParticipantsView()

    channel = @getData()

    @input = new ReplyInputWidget {channel}

    @listController.getListView().on 'ItemWasAdded', @bound 'privateMessageAdded'
    @listController.getListView().on 'ItemWasRemoved', @bound 'privateMessageRemoved'


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


  viewAppended: ->

    @addSubView @participantsView
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