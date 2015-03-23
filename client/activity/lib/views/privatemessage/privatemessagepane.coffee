kd                               = require 'kd'
KDButtonView                     = kd.ButtonView
KDCustomHTMLView                 = kd.CustomHTMLView
KDFormViewWithFields             = kd.FormViewWithFields
KDView                           = kd.View
ActivityAutoCompleteUserItemView = require '../activityautocompleteuseritemview'
ParticipantSearchController      = require './participantsearchcontroller'
MessagePane                      = require '../messagepane'
PrivateMessageForm               = require './privatemessageform'
PrivateMessageListItemView       = require './privatemessagelistitemview'
PrivateMessageSettingsView       = require './privatemessagesettingsview'
ReplyInputWidget                 = require './replyinputwidget'
ReplyPreviousLink                = require './replypreviouslink'
showError                        = require 'app/util/showError'
AvatarView                       = require 'app/commonviews/avatarviews/avatarview'
dateFormat                       = require 'dateformat'
isMyPost                         = require 'app/util/isMyPost'
remote                           = require('app/remote').getInstance()



module.exports = class PrivateMessagePane extends MessagePane

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
      kd.utils.defer @bound 'scrollDown'
      kd.utils.wait 300, =>
        @unsetClass 'translucent'
        @input.input.setPlaceholder ''
        @scrollDown()

    list = @listController.getListView()

    list.on 'ItemWasAdded',     @bound 'messageAdded'
    list.on 'ItemWasRemoved',   @bound 'messageRemoved'
    list.on 'EditMessageReset', @input.bound 'focus'
    list.on 'ItemWasExpanded',  @bound 'messageExpanded'

    @input.input.on 'InputHeightChanged', @bound 'handleAutoGrow'

    @input.input.on 'focus', =>
      @scrollView.wrapper.emit 'MutationHappened'
      # sometimes el.scrollHeight gives false values
      # thus this terrible hack to reflow and get the correct values - SY
      @scrollView.wrapper.addSubView v = new KDCustomHTMLView
      kd.utils.defer -> v.destroy()

    @input.input.on 'blur', => @setCss 'height', 'none'

    @listenWindowResize()


  handleAutoGrow: ->

    headerHeight = @participantsView.getHeight()
    inputHeight  = @input.getHeight()
    paneHeight   = @getHeight()

    # 50 smaller than two lines
    # bigger than a single line
    # eventually needs an initial height - SY
    if inputHeight > 50
    then @scrollView.setHeight paneHeight - inputHeight - headerHeight
    else @scrollView.setAttribute 'style', ''

    @scrollDown()
    @_windowDidResize()


  _windowDidResize: (event) ->

    kd.utils.defer => @scrollView.wrapper.emit 'MutationHappened'


  #
  # DATA EVENTS
  #

  bindChannelEvents: (channel) ->

    return  unless channel

    super channel

    channel.on 'AddedToChannel', @bound 'addParticipant'
    channel.on 'RemovedFromChannel', @bound 'removeParticipant'


  realtimeMessageArrived: (message) ->

    wasAtBottom = @isPageAtBottom()
    item = @appendMessage message

    @scrollDown item  if wasAtBottom


  #
  # ADDING MESSAGES
  #

  appendMessage: (message, index) -> @listController.addItem message, index or @listController.getItemCount()


  prependMessage: (message) -> @listController.addItem message, 0


  addMessageDeferred: (item, i, total) ->

    # temp.
    # until we have a separate message type for collaboration messages
    # we need to do this to be able to distinguish them - SY
    if item.payload?.collaboration then @setOption 'collaboration', yes

    # Super method defers adding list items to minimize page load
    # congestion. This function is overrides super function to render
    # all conversation messages to be displayed at the same time
    @prependMessage item
    @emit 'ListPopulated'  if i is total - 1


  putMessage: (message, index) ->

    @appendMessage message, index or @listController.getItemCount()


  replaceFakeItemView: (message) ->

    item = super message
    @scrollDown item


  #
  # DECORATORS
  #

  getSiblings: (index) ->

    prevSibling = @listController.getListItems()[index-1]
    nextSibling = @listController.getListItems()[index+1]

    return [prevSibling, nextSibling]


  resetPadding: ->

    listView = @listController.getView()

    if (listView.hasClass 'padded') and (@scrollView.getHeight() < listView.getHeight())
      listView.unsetClass 'padded'
      return yes

    return no


  messageExpanded: () ->

    @scrollDown()  if @resetPadding()

    @scrollView.wrapper.emit 'MutationHappened'


  messageAdded: (item, index) ->

    data         = item.getData()
    listView     = @listController.getView()

    {applyConsequency, hasSameOwner} = helper

    @resetPadding()

    # TODO: This is a temporary fix,
    # we need to revisit this part.
    # messageAdded & messageRemoved has a race
    # condition problem. ~Umut
    if data.clientRequestId and not data.isFake
      fakeItem = @fakeMessageMap[data.clientRequestId]
      if fakeItem
        applyConsequency fakeItem.hasClass('consequent'), item
        return

    @applyDayMark item, index
    @putNewMessageMark()

    return  if data.typeConstant in ['join', 'leave']

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

    [currentDate, otherDate] = @extractDates item, index

    return Math.abs(currentDate - otherDate) > 3e5


  #
  # LIST CREATION
  #

  populate: ->

    @setClass 'translucent'
    @input.input.setPlaceholder 'Loading...'

    super =>

      listView = @listController.getView()
      @listPreviousReplies()  if listView.getHeight() <= global.innerHeight


  fetch: (options = {}, callback) ->

    super options, (err, data) =>

      channel = @getData()
      channel.replies = data
      callback err, data


  listPreviousReplies: do ->

    inProgress = false

    (event) ->

      return  if inProgress

      inProgress   = true
      {appManager} = kd.singletons
      {first}      = @listController.getListItems()
      {body}       = global.document

      return  unless first

      from = first.getData().createdAt

      @listPreviousLink.updatePartial 'Fetching previous messages...'

      @fetch {from, limit: 100}, (err, items = []) =>

        return showError err  if err

        items.forEach (item, i) =>
          {wrapper} = @scrollView
          previousScrollHeight = wrapper.getScrollHeight()
          @prependMessage item
          currentScrollHeight = wrapper.getScrollHeight()
          currentScrollTop    = wrapper.getScrollTop()
          wrapper.setScrollTop currentScrollTop + (currentScrollHeight - previousScrollHeight)

        if items.length is 0
        then @listPreviousLink.hide()
        else @listPreviousLink.updatePartial 'Pull to view more'

        inProgress = false


  #
  # SUBVIEWS
  #

  createInputWidget: ->

    channel = @getData()
    @input  = new ReplyInputWidget {channel, cssClass : 'private'}

    @input.on 'EditModeRequested', @bound 'editLastMessage'


  addParticipant: (participant) ->

    return  unless participant
    return  if @participantMap[participant._id]?

    participant.id = participant._id

    @heads.addSubView avatar = new AvatarView
      size      :
        width   : 25
        height  : 25
      origin    : participant

    @participantMap[participant._id] = avatar


  removeParticipant: (participant) ->

    return  unless participant
    return  unless @participantMap[participant._id]?

    remote.cacheable 'JAccount', participant._id, (err, account) =>

      return warn err  if err

      @participantMap[participant._id].destroy()
      delete @participantMap[participant._id]

      @autoComplete.removeSelectedParticipant account


  createPreviousLink: ->

    @listPreviousLink = new ReplyPreviousLink
      delegate : @listController
      linkCopy : 'Show previous replies'
    , @getData()


  createParticipantsView : ->

    {participantsPreview} = @getData()

    @participantsView = new KDCustomHTMLView
      cssClass    : 'chat-heads'
      partial     : '<span class="description">Chat between</span>'


    @participantsView.addSubView @actionsMenu = new PrivateMessageSettingsView {}, @getData()

    @forwardEvent @actionsMenu, 'LeftChannel'

    @participantsView.addSubView @heads = new KDCustomHTMLView
      cssClass    : 'heads'

    @addParticipant participant for participant in participantsPreview

    @participantsView.addSubView @newParticipantButton = new KDButtonView
      cssClass    : 'new-participant'
      iconOnly    : yes
      callback    : @bound 'toggleAutoCompleteInput'


  toggleAutoCompleteInput: ->

    @emit 'NewParticipantButtonClicked'

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
      submit             : (e) -> e.preventDefault()

    @autoComplete = new ParticipantSearchController
      name                : 'userController'
      placeholder         : 'Type a username...'
      itemClass           : ActivityAutoCompleteUserItemView
      itemDataPath        : 'profile.nickname'
      fetchInterval       : 0
      outputWrapper       : new KDView cssClass: 'hidden'
      listWrapperCssClass : 'private-message hidden'
      submitValuesAsText  : yes
      dataSource          : @bound 'fetchAccounts'

    @autoCompleteForm.inputs.recipient.addSubView @autoComplete.getView()

    @autoComplete.on 'ItemSelected', @bound 'toggleAutoCompleteInput'

    @autoComplete.on 'ItemListChanged', (count) =>
      participant  = @autoComplete.getSelectedItemData()[count - 1]
      options      =
        channelId  : @getData().getId()
        accountIds : [participant.socialApiId]

      {channel} = kd.singleton 'socialapi'
      channel.addParticipants options, (err, result) =>
        if err
          showError err
          @autoComplete.reset()
          return

        @emit 'AddedParticipant', participant


  viewAppended: ->

    @addSubView @participantsView
    @addSubView @autoCompleteForm

    @addSubView @scrollView

    {wrapper} = @scrollView
    wrapper.addSubView @listPreviousLink
    wrapper.addSubView @listController.getView()
    @addSubView @input  if @input
    @populate()
    @setScrollTops()


  #
  # UI EVENTS/DIRECTIVES
  #

  bindLazyLoader: ->

    {wrapper} = @scrollView
    wrapper.on 'TopLazyLoadThresholdReached', kd.utils.throttle 200, @bound 'listPreviousReplies'
    wrapper.on 'LazyLoadThresholdReached', kd.utils.throttle 200, @bound 'handleThresholdReached'


  handleThresholdReached: -> @handleFocus()


  editLastMessage: ->

    items = @listController.getListItems().slice(0).reverse()
    return item.showEditWidget() for item in items when isMyPost item.getData()


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

    {focused} = kd.singletons.windowController
    @glance()  if focused and @active and @isPageAtBottom()


  scrollDown: (item) ->

    return  unless @active
    {wrapper} = @scrollView
    wrapper.setScrollTop wrapper.getScrollHeight()


  show: ->

    super

    @_windowDidResize()

    kd.utils.defer @bound 'focus'


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
