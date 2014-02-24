class ChatPane extends JView

  constructor: (options = {}, data) ->

    floatingCssClass = if options.floating then "floating" else ""
    options.cssClass = KD.utils.curry "workspace-chat", floatingCssClass

    super options, data

    @itemClass   = @getOptions().itemClass or ChatItem
    @unreadCount = 0
    @workspace   = @getDelegate()
    {@chatRef}   = @workspace

    @createElements()
    @createDock()
    @bindRemoteEvents()

    @on "NewChatItemCreated", =>
      @checkEmbeddableContent()

    @on "NewChatItemPosted", =>
      @input.setValue ""
      @input.setFocus()

  bindRemoteEvents: ->
    @chatRef.on "child_added", (snapshot) =>
      unless @isVisible() or @getOptions().floating
        @updateCount ++@unreadCount

      @addNew @workspace.reviveSnapshot snapshot

  updateCount: (count) ->
    @title.updatePartial "Chat (#{++@unreadCount})"
    @dock.setClass "pulsing"

  createElements: ->
    @messages     = new KDView cssClass : "messages"
    @input        = new KDHitEnterInputView
      placeholder : "Type your message and hit enter"
      callback    : @bound "createMessage"

  createMessage: ->
    @sendMessage
      message: @input.getValue()
      by     : KD.nick()

    @emit "NewChatItemPosted"

  createDock: ->
    @dock        = new KDView
      cssClass   : "dock"
      click      : =>
        @dock.unsetClass "pulsing"
        @toggleClass "active"
        @toggle.toggleClass "active"
        @unreadCount = 0
        @title.updatePartial "Chat"
        @emit "WorkspaceChatClosed"  unless @isVisible()

    @title       = new KDCustomHTMLView
      tagName    : "span"
      partial    : "Chat"

    @toggle      = new KDView
      cssClass   : "toggle"

    @dock.addSubView @toggle
    @dock.addSubView @title

  isVisible: -> return @hasClass "active"

  sendMessage: (messageData) ->
    message  =
      user   : { nickname: KD.nick() }
      time   : Date.now()
      body   : messageData.message

    @chatRef.child(message.time).set message

  addNew: (details) ->
    ownerNickname    = details.user.nickname
    ownerAccount     = @workspace.users[ownerNickname] or { nickname: ownerNickname }
    params           = { details, ownerNickname, ownerAccount }
    @lastMessageBody = details.body

    if ownerNickname is KD.nick()
    then forceScrollToBottom = yes
    else forceScrollToBottom = @isScrollTopAtBottom()

    if @lastChatItemOwner is ownerNickname
      @appendToChatItem params
      @updateDate details.time
    else
      @createNewChatItem params

    @scrollToBottom()  if forceScrollToBottom

  createNewChatItem: (params) ->
    {details, ownerAccount, ownerNickname} = params
    @lastChatItem      = new @itemClass details, ownerAccount
    @lastChatItemOwner = ownerNickname
    @messages.addSubView @lastChatItem
    @updateDate details.time
    @lastMessage = @lastChatItem.message
    @emit "NewChatItemCreated"

  appendToChatItem: (params) ->
    {details}  = params
    @lastChatItem.messageList.addSubView @lastMessage = new KDCustomHTMLView
      partial  : details.body
      cssClass : "tw-chat-message"

    @emit "NewChatItemCreated"

  updateDate: (timestamp) ->
    @lastChatItem.timeAgo.setData new Date timestamp

  checkEmbeddableContent: ->
    return if not @lastMessage or not @lastMessageBody

    element  = @lastMessage.getElement()
    words    = @lastMessageBody.split " "
    urlRegex = /^(https?:\/\/)([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/
    hasUrl   = no

    for word, index in words
      if urlRegex.test word
        hasUrl = yes
        words.splice index, 1, "<a href='#{word}'>#{word}</a>"

    if hasUrl
      element.innerHTML = words.join " "
      element.classList.add "tw-chat-media"

  scrollToBottom: ->
    element = @messages.getElement()
    element.scrollTop = element.scrollHeight

  isScrollTopAtBottom: ->
    element = @messages.getElement()
    height = parseInt window.getComputedStyle(element).height, 10
    return (element.scrollTop + height) is element.scrollHeight

  pistachio: ->
    """
      {{> @dock}}
      {{> @messages}}
      <div class="input-container">
        {{> @input}}
      </div>
    """
