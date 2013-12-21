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
        @sendMessage
          message: @input.getValue()
          by     : KD.nick()
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

  sendMessage: (messageData) ->
    message  =
      user   : { nickname: KD.nick() }
      time   : Date.now()
      body   : messageData.message

    @chatRef.child(message.time).set message

  addNew: (details) ->
    ownerNickname = details.user.nickname
    ownerAccount  = @workspace.users[ownerNickname] or { nickname: ownerNickname }
    params        = { details, ownerNickname, ownerAccount }

    if @lastChatItemOwner is ownerNickname
      @appendToChatItem params
      @updateDate details.time
      return  @scrollToTop()

    @createNewChatItem params

  createNewChatItem: (params) ->
    {details, ownerAccount, ownerNickname} = params
    @lastChatItem      = new @itemClass details, ownerAccount
    @lastChatItemOwner = ownerNickname
    @messages.addSubView @lastChatItem
    @updateDate details.time
    @scrollToTop()

  appendToChatItem: (params) ->
    {details} = params
    @lastChatItem.messageList.addSubView new KDCustomHTMLView
      partial  : KD.utils.xssEncode details.body
      cssClass : details.cssClass

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
