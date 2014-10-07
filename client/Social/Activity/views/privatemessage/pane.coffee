class PrivateMessagePane extends MessagePane

  TEST_MODE = on

  constructor: (options = {}, data) ->

    options.lastToFirst   = yes
    options.scrollView    = no
    options.itemClass   or= PrivateMessageListItemView

    super options, data


    # To keep track of who are the shown participants
    # This way we are preventing to be duplicates
    # on page even if events from backend come more than
    # once.
    @participantMap = {}

    @createPreviousLink()
    @createParticipantsView()
    @createAddParticipantForm()

    @on 'ListPopulated', =>
      KD.utils.defer @bound 'scrollDown'
      KD.utils.wait 300, =>
        @unsetClass 'translucent'
        @input.input.setPlaceholder ''
        @scrollDown()

    list = @listController.getListView()

    list.on 'ItemWasAdded',     @bound 'messageAdded'
    list.on 'ItemWasRemoved',   @bound 'messageRemoved'
    list.on 'EditMessageReset', @input.bound 'focus'

    @on 'TopLazyLoadThresholdReached', KD.utils.throttle 200, @bound 'listPreviousReplies'






  setScrollTops: ->

    {body} = document
    @lastScrollTops.body = body.scrollTop or body.scrollHeight


  applyScrollTops: ->

    {body} = document
    body.scrollTop = @lastScrollTops.body


  replaceFakeItemView: (message) ->
    index = @listController.getListView().getItemIndex @fakeMessageMap[message.clientRequestId]
    item  = @putMessage message, index
    @removeFakeMessage message.clientRequestId
    @scrollDown item


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

    super value, clientRequestId
    @input.empty()


  applyTestPatterns: (value) ->

    if value.match /^\/unleashtheloremipsum/
      [_, interval, batchCount] = value.split " "
      [interval, batchCount] = parse interval, batchCount
      PrivateMessageLoadTest.run this, interval, batchCount
    else if value.match /^\/analyzetheloremipsum/
      PrivateMessageLoadTest.analyze this


  bindChannelEvents: (channel) ->

    return  unless channel

    super channel

    channel.on 'AddedToChannel', @bound 'addParticipant'





  # this is the realtime event handler for messages
  addMessage: (message) ->

    return  if message.account._id is KD.whoami()._id

    wasAtBottom = @isPageAtBottom()
    item = @prependMessage message, @listController.getItemCount()

    @scrollDown item  if wasAtBottom



  prependMessage: (message, index) ->

    return @listController.addItem message, index


  putMessage: (message, index) ->

    @appendMessage message, index or @listController.getItemCount()


  hasSameOwner = (a, b) -> a.getData().account._id is b.getData().account._id


  listPreviousReplies: do ->

    inProgress = false

    (event) ->

      return  if inProgress

      inProgress   = true
      {appManager} = KD.singletons
      {first}      = @listController.getListItems()
      {body}       = document

      return  unless first

      from = first.getData().createdAt

      @listPreviousLink.updatePartial 'Fetching previous messages...'

      @fetch {from, limit: 100}, (err, items = []) =>

        return KD.showError err  if err

        items.forEach (item, i) =>
          {scrollHeight} = body
          @appendMessage item, 0
          body.scrollTop += body.scrollHeight - scrollHeight

        if items.length is 0
        then @listPreviousLink.hide()
        else @listPreviousLink.updatePartial 'Pull or click here to view more'

        inProgress = false


  messageAdded: (item, index) ->

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


  appendMessageDeferred: (item, i, total) ->
    # Super method defers adding list items to minimize page load
    # congestion. This function is overrides super function to render
    # all conversation messages to be displayed at the same time
    @appendMessage item
    @emit 'ListPopulated'  if i is total - 1



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


  createPreviousLink: ->

    @listPreviousLink = new ReplyPreviousLink
      delegate : @listController
      click    : @bound 'listPreviousReplies'
      linkCopy : 'Show previous replies'
    , @getData()


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

        @autoComplete.getView().once 'blur',=>
          @autoCompleteForm.toggleClass 'active'
          @newParticipantButton.toggleClass 'active'
          @input.input.setFocus()


  createAddParticipantForm: ->

    @autoCompleteForm = new KDFormViewWithFields
      title              : 'START A CHAT WITH:'
      cssClass           : 'new-message-form inline'
      fields             :
        recipient        :
          itemClass      : KDView
      submit             : (e) ->
        e.preventDefault()


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


  show: ->

    super

    KD.utils.defer @bound 'focus'


  defaultFilter: 'Most Recent'


  focus: -> @input.focus()
