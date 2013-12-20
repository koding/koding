class ChatPane extends JView

  constructor: (options = {}, data) ->

    floatingCssClass = if options.floating then "floating" else ""
    options.cssClass = KD.utils.curry "workspace-chat", floatingCssClass

    super options, data

    @unreadCount = 0
    @workspace   = @getDelegate()
    {@chatRef}   = @workspace

    @createElements()
    @createDock()
    @bindRemoteEvents()

  bindRemoteEvents: ->
    @chatRef.on "child_added", (snapshot) =>
      unless @isVisible() or @getOptions().floating
        @updateCount ++@unreadCount

      @addNew snapshot.val()

  updateCount: (count) ->
    @title.updatePartial "Chat (#{++@unreadCount})"
    @dock.setClass "pulsing"

  createElements: ->
    @messages     = new KDView cssClass : "messages"
    @input        = new KDHitEnterInputView
      placeholder : "Type your message and hit enter"
      callback    : =>
        @sendMessage @input.getValue()
        @input.setValue ""
        @input.setFocus()

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

  sendMessage: (message) ->
    message  =
      user   : { nickname: KD.nick() }
      time   : Date.now()
      body   : message

    @chatRef.child(message.time).set message

  addNew: (details) ->
    ownerNickname = details.user.nickname
    if @lastChatItemOwner is ownerNickname
      @lastChatItem.messageList.addSubView new KDCustomHTMLView
        partial : Encoder.XSSEncode details.body
      @updateDate details.time
      return  @scrollToTop()

    @lastChatItem      = new ChatItem details, @workspace.users[ownerNickname]
    @lastChatItemOwner = ownerNickname
    @messages.addSubView @lastChatItem
    @updateDate details.time
    @scrollToTop()

  updateDate: (timestamp) ->
    @lastChatItem.timeAgo.setData new Date timestamp

  scrollToTop: ->
    $messages = @messages.$()
    $messages.scrollTop $messages[0].scrollHeight

  pistachio: ->
    """
      {{> @dock}}
      {{> @messages}}
      <div class="input-container">
        {{> @input}}
      </div>
    """
