class PrivateMessagePane extends MessagePane

  CONSEQUENCY_DELAY = 3e5

  constructor: (options = {}, data) ->

    options.lastToFirst         = no
    options.scrollView          = no
    options.noItemFoundWidget   = no
    options.startWithLazyLoader = no
    options.itemClass         or= PrivateMessageListItemView

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
    @on 'LazyLoadThresholdReached', KD.utils.throttle 200, @bound 'handleFocus'


  #
  # DATA EVENTS
  #

  bindChannelEvents: (channel) ->

    return  unless channel

    super channel

    channel.on 'AddedToChannel', @bound 'addParticipant'


  realtimeMessageArrived: (message) ->

    return  if message.account._id is KD.whoami()._id

    wasAtBottom = @isPageAtBottom()
    item = @appendMessage message

    @scrollDown item  if wasAtBottom


  #
  # ADDING MESSAGES
  #

  appendMessage: (message) -> @listController.addItem message, @listController.getItemCount()


  prependMessage: (message) -> @listController.addItem message, 0


  addMessageDeferred: (item, i, total) ->
    # Super method defers adding list items to minimize page load
    # congestion. This function is overrides super function to render
    # all conversation messages to be displayed at the same time
    @prependMessage item
    @emit 'ListPopulated'  if i is total - 1


  putMessage: (message, index) ->

    @appendMessage message, index or @listController.getItemCount()


  replaceFakeItemView: (message) ->
    index = @listController.getListView().getItemIndex @fakeMessageMap[message.clientRequestId]
    item  = @putMessage message, index
    @removeFakeMessage message.clientRequestId
    @scrollDown item


  #
  # DECORATORS
  #

  getSiblings: (index) ->

    prevSibling = @listController.getListItems()[index-1]
    nextSibling = @listController.getListItems()[index+1]

    return [prevSibling, nextSibling]


  messageAdded: (item, index) ->

    data         = item.getData()
    listView     = @listController.getView()
    headerHeight = @heads?.getHeight() or 0

    {applyConsequency, hasSameOwner} = helper

    if window.innerHeight - headerHeight < listView.getHeight()
      listView.unsetClass 'padded'

    # TODO: This is a temporary fix,
    # we need to revisit this part.
    # messageAdded & messageRemoved has a race
    # condition problem. ~Umut
    if data.clientRequestId and not data.isFake
      fakeItem = @fakeMessageMap[data.clientRequestId]
      applyConsequency fakeItem.hasClass('consequent'), item

      return

    @applyDayMark item, index
    @putNewMessageMark()

    return  if @doesBreakConsequency item, index

    [prev, next] = @getSiblings index

    applyConsequency hasSameOwner(item, prev), item  if prev
    applyConsequency hasSameOwner(item, next), next  if next


  messageRemoved: (item, index) ->

    return  if item.getData().isFake

    [prev, next]                     = @getSiblings index
    {applyConsequency, hasSameOwner} = helper

    if next and prev
      applyConsequency hasSameOwner(prev, next), next
    else if next
      next.unsetClass 'consequent'


  extractDates: (item, index) ->

    [prev, next] = @getSiblings index

    currentDate = new Date item.getData().createdAt
    otherDate   = new Date prev.getData().createdAt  if prev
    otherDate   = new Date next.getData().createdAt  if next

    return [currentDate, otherDate]


  putNewMessageMark: (item, index) ->


  applyDayMark: (item, index) ->

    [currentDate, otherDate] = @extractDates item, index

    if otherDate and currentDate.getDate() isnt otherDate.getDate()

      [prev, next] = @getSiblings index

      exactDate = new Date if prev then currentDate.getTime() else otherDate.getTime()
      dayMark   = helper.createDayMark exactDate

      if prev
      then prev.parent.addSubView dayMark
      else if next
      then next.parent.addSubView dayMark, null, yes

    return dayMark


  # i know, i invented a word - SY
  doesBreakConsequency: (item, index) ->

    [prev, next] = @getSiblings index
    otherItem    = prev or next
    hasSame      = otherItem and helper.hasSameOwner item, otherItem

    [currentDate, otherDate] = @extractDates item, index

    return no  unless otherDate

    return Math.abs(currentDate - otherDate) > CONSEQUENCY_DELAY and hasSame


  #
  # LIST CREATION
  #

  populate: ->

    @setClass 'translucent'
    @input.input.setPlaceholder 'Loading...'

    super =>

      listView = @listController.getView()
      @listPreviousReplies()  if listView.getHeight() <= window.innerHeight


  fetch: (options = {}, callback) ->

    super options, (err, data) =>

      channel = @getData()
      channel.replies = data
      @listPreviousLink.updateView data
      callback err, data


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
          @prependMessage item
          body.scrollTop += body.scrollHeight - scrollHeight

        if items.length is 0
        then @listPreviousLink.hide()
        else @listPreviousLink.updatePartial 'Pull or click here to view more'

        inProgress = false


  #
  # SUBVIEWS
  #

  createInputWidget: ->

    channel = @getData()

    @input = new ReplyInputWidget {channel}

    @input.on 'EditModeRequested', @bound 'editLastMessage'


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


  viewAppended: ->

    @addSubView @participantsView
    @addSubView @autoCompleteForm
    @addSubView @listPreviousLink
    @addSubView @listController.getView()
    @addSubView @input  if @input
    @populate()


  #
  # UI EVENTS/DIRECTIVES
  #

  editLastMessage: ->

    items = @listController.getItemsOrdered().slice(0).reverse()
    return item.showEditWidget() for item in items when KD.isMyPost item.getData()


  # as soon as the enter key down,
  # we create a fake itemview and put
  # it to dom. once the response from server
  # comes back, it will replace the fake one
  # with the real one.
  handleEnter: (value, clientRequestId) ->

    return  unless value

    super value, clientRequestId
    @input.empty()


  handleFocus: ->

    {focused} = KD.singletons.windowController
    @glance()  if focused and @active and @isPageAtBottom()


  scrollDown: (item) ->

    return  unless @active
    document.body.scrollTop = document.body.scrollHeight * 2


  setScrollTops: ->

    {body} = document
    @lastScrollTops.body = body.scrollTop or body.scrollHeight


  applyScrollTops: ->

    {body} = document
    body.scrollTop = @lastScrollTops.body


  show: ->

    super

    KD.utils.defer @bound 'focus'


  focus: -> @input.focus()


  glance: ->

    super

    @newMessagesMark?.destroy()
    @newMessagesMark = null


  fetchAccounts: PrivateMessageForm::fetchAccounts


  #
  # SUPER OVERRIDES
  #

  defaultFilter: 'Most Recent'
  setFilter: ->


  #
  # HELPERS
  #

  helper =

    hasSameOwner : (a, b) -> a.getData().account._id is b.getData().account._id

    applyConsequency : (condition, item) ->

      if condition
      then item.setClass 'consequent'
      else item.unsetClass 'consequent'

    createDayMark : (date) ->

      date.setHours 0, 0, 0, 0

      return new KDCustomHTMLView
        tagName    : 'time'
        partial    : dateFormat date, 'dddd, mmmm dS, yyyy'
        attributes :
          datetime : date.toUTCString()

    parse : (args...) -> args.map (item) -> parseInt item




