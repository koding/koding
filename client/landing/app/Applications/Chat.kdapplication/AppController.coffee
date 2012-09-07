###
The main controller to keep track of channels the current client
are in, handling the communication between the ChatView and each
Channel instance.
###
TOPICREGEX = /[#|@]([\w-]+)/g

class Chat12345 extends AppController
  {mq} = bongo
  PUBLIC = 'public'

  constructor:(options = {}, data)->
    options.view = new ChatView
      cssClass : "content-page chat"

    super options, data

    @account = KD.whoami()
    @username = @account?.profile?.nickname
    @username = "Guest"+__utils.getRandomNumber() if @username is "Guest"

    @channels = {}
    @broadcaster = mq.subscribe "private-KDPublicChat"

  bringToFront:()->
    super name : 'Chat'#, type : 'background'

  loadView:(mainView)->
    @joinChannel "@#{@username}"
    @joinChannel PUBLIC

  joinChannel: (name) ->
    view = @getOptions().view
    channelPaneInstance = view.addChannelTab name

    if channel = @channels[name]      
      return channel

    # When the tab is closed, remove the channel reference
    # and sign the user off from the channel
    channelPaneInstance.on "KDObjectWillBeDestroyed", =>
      delete @channels[name]
      mq.presenceOff @username, name

    channelName = "client-#{name}"

    channel = new Channel 
      name: name
      view: channelPaneInstance

    # Presence received has format [key, "bind" || "unbind"]
    mq.presenceOn @username, name, ([presence, status]) =>
      if status is "bind"
        channel.addOnlineUser presence
      else if status is "unbind"
        channel.removeOfflineUser presence

    channel.view.registerListener
      KDEventTypes  : "AutoCompleteNeedsMemberData"
      listener      : @
      callback      : (pubInst,event)=>
        {callback,inputValue,blacklist} = event
        @fetchAutoCompleteForMentionField inputValue,blacklist,callback 

    # When the channel's view receives chat input, parse the body
    # and broadcast it to corresponding channels.
    channel.view.on "ChatMessageSent", (messageBody) =>
      @parseMessage messageBody, name
      @broadcastOwnMessage messageBody, name 
      # Also broadcast to public channel
      if name isnt PUBLIC
        @broadcastOwnMessage messageBody, PUBLIC, name

    # Delegates to the channel to handle received message
    @broadcaster.on channelName, (msg) =>      
      @deliverMessageToChannel channel, msg      

    @channels[name] = channel

  ###
  # Parses the message body for any reference to a channel, then
  # joins the user to that channel. It will then broadcast the 
  # message body to the newly joined channel.
  ###
  parseMessage: (message, fromChannel) ->
    while match = TOPICREGEX.exec message
      toChannel = match[0]
      if toChannel isnt fromChannel
        @broadcastOwnMessage message, toChannel, fromChannel

  ###
  # Broadcasts the message to channel toChannel. If fromChannel
  # is provided, will set a property on the chat item so that
  # channel reference will be rendered from the view.
  ###
  broadcastOwnMessage: (messageBody, toChannel, fromChannel) ->
    chatItem = 
      author: @username
      body: messageBody
      meta: {createdAt: new Date().toISOString()}

    chatItem.channel = fromChannel if fromChannel?.match(TOPICREGEX)

    channelMQName = "client-#{toChannel}"
    @broadcaster.emit channelMQName, JSON.stringify(chatItem)
    return unless @channels[toChannel]
    #chatItem.author = "me"
    @deliverMessageToChannel @channels[toChannel], chatItem

  deliverMessageToChannel: (channel, message) ->
    itemInstance = channel.messageReceived message
    itemInstance.registerListener
      KDEventTypes: 'click'
      listener    : @
      callback    : (pubInst, event) =>
        return unless $(event.target).is('a.open-new-chat')
        channelName = $(event.target).text()
        @joinChannel channelName

  fetchAutoCompleteForMentionField:(inputValue,blacklist,callback)->
    bongo.api.JAccount.byRelevance inputValue,{blacklist},(err,accounts)->
      callback accounts

class Channel extends KDEventEmitter
  constructor: (options = {}, data) ->
    @messages = []
    @unreadCount = 0
    @participants = {}
    @name = options.name
    @view = options.view

    # Remove unread count when the tab is active
    @view.listenTo
      KDEventTypes: [ eventType: "KDTabPaneActive" ]
      listenedToInstance: @view
      callback: => 
        @unreadCount = 0
        @view.setUnreadCount @unreadCount

  addOnlineUser: (name) ->
    bongo.api.JAccount.one "profile.nickname" : name, (err, account)=>
      viewInstance = @view.addRosterItem account
      @participants[name] = viewInstance
      viewInstance

  removeOfflineUser: (name) ->
    viewInstance = @participants[name]
    @view.removeRosterItem viewInstance

  messageReceived: (message) ->
    @messages.push message
    unless @view.isActive()
      @unreadCount++ 
      @view.setUnreadCount @unreadCount
    @view.newMessage message

class ChatView extends KDView
  viewAppended: ->
    @rosterTabView = new KDTabView
    @chatTabView = new KDTabView
    
    @addSubView splitView = new KDSplitView
      sizes: ["20%","80%"]
      views: [@rosterTabView, @chatTabView]

    @rosterTabView.addPane new TabPaneViewWithList 
      name: "topics"
      unclosable: true
      subItemClass: ChannelListItemView

  ###
  # Called by ChatController to create a tab view for new channel
  ###
  addChannelTab: (name) ->
    channelTabPane = @chatTabView.getPaneByName name
    if channelTabPane
      @chatTabView.showPaneByName name
      return channelTabPane

    tabPane = @chatTabView.addPane new ChannelView
      name: name
      listHeight: 500

###
This is a view for a tab pane that has a list view in there.
###
class TabPaneViewWithList extends KDTabPaneView
  constructor: (options = {}, data) ->
    super options, data
    controllerOptions = options.controllerOptions or {}
    
    if options.subItemClass
      controllerOptions.subItemClass = options.subItemClass

    @listController = new KDListViewController controllerOptions
    @listView = @listController.getListView()
    @controllerView = @listController.getView()

    if options.listHeight
      @controllerView.setHeight 500

    if options.items
      @listController.instantiateListItems options.items

  viewAppended: ->
    @addSubView @controllerView
    if @getOptions().unclosable
      @hideTabCloseIcon()

  addItem: (item, index, animation) ->
    @listView.addItem item, index, animation

class ChannelView extends KDTabPaneView
  constructor: (options = {}, data) ->  
    super options, data

    @chatController = new KDListViewController
      subItemClass: ChatListItemView
    @rosterController = new KDListViewController
      subItemClass: ChannelListItemView

    @chatController.getView().setHeight options.listHeight || 500
    @rosterController.getView().setHeight options.listHeight || 500

  viewAppended: ->
    @addSubView splitView = new KDSplitView
      sizes: ["60%","40%"]
      views: [
        @chatController.getView()
        @rosterController.getView()
      ]
    splitView.setHeight 500
    @addSubView inputForm = new ChatInputForm delegate : @

  addRosterItem: (item) ->
    @rosterController.getListView().addItem item

  removeRosterItem: (itemInstance) ->
    @rosterController.getListView().removeItem itemInstance

  newMessage: (message) ->
    @chatController.getListView().addItem message

  isActive: ->
    @getDomElement().hasClass "active"

  setUnreadCount: (count) ->
    if count > 0
      title = "#{@name} (<span class='unread'>#{count}</span>)"
    else
      title = "#{@name}"

    @tabHandle.getDomElement().find("b").html title

class ChatListItemView extends KDListItemView
  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    parsedBody = @getData().body.replace(TOPICREGEX, "<a class='open-new-chat' href='#'>$&</a>")
    parsedChannel = @getData().channel?.replace(TOPICREGEX, "<a class='open-new-chat' href='#'>$&</a>")

    """
    <div class='meta'>      
      <span class='time'>[{{#(meta.createdAt)}}] </span>
      #{if @getData().channel? then "<span>[#{parsedChannel}]</span>" else ''}
      <span class="author-wrapper">{{#(author)}}: </span>
      <span>#{parsedBody}</span>
    </div>
    """

class ChannelListItemView extends KDListItemView
  constructor: (options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    super
    @avatar = new AvatarView {size : width : 16, height : 16},data
    @profileText = new ProfileTextView {shouldShowNick: yes},data

  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    """
      <span class='avatar'>{{> @avatar}}</span>
      {{> @profileText}} (@#{@getData().profile.nickname})
    """

class ChatInputForm extends KDFormView
  constructor: ->
    super
    @input = new KDAutoComplete
      placeholder: "Click here to reply"
      name: "chatInput"
      label: new KDLabelView
        title: "chatInput"
      cssClass: "fl"
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Reply field is empty..."

    @sendButton = new KDButtonView
      title: "Send"
      style: "clean-gray inside-button"
      callback: =>
        input = @mentionController.getView()
        chatMsg = input.getValue()

        input.setValue ""
        input.blur()
        input.$().blur()

        @getDelegate().emit 'ChatMessageSent', chatMsg

    @mentionController = new MentionAutoCompleteController
      view                : @input
      itemClass           : MemberAutoCompleteItemView
      form                : @
      itemDataPath        : "profile.nickname"
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in @mentionController.getSelectedItemData())
        @getDelegate().propagateEvent KDEventType : "AutoCompleteNeedsMemberData", {inputValue,blacklist,callback}

    @mentionAutoCompleteView = @mentionController.getView()

  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    """
    <div class="formline">
      <div>
        {{> @mentionAutoCompleteView}}
        {{> @sendButton}}
      </div>
    </div>
    """

class MentionAutoCompleteController extends KDAutoCompleteController
  getLastInputWord: () ->
    inputValue = @getView().getValue()
    inputValue.split(/\s/).pop()

  keyUpOnInputView:(inputView, event)=>
    return if event.keyCode in [9,38,40] #tab
    #if event.shiftKey and event.which is 50 # Shift+2 = @

    lastWord = @getLastInputWord()
    if lastWord.length > 1 and lastWord[0] is '@'
      @updateDropdownContents()
    no

  fetch:(callback)->
    lastWord = @getLastInputWord()
    return if lastWord.length <= 1 or lastWord[0] isnt '@'
    @dropdownPrefix = lastWord.match(/^@(.*)/)[1]

    args = {}
    if @getOptions().fetchInputName
      args[@getOptions().fetchInputName] = @getView().getValue()
    else
      args = inputValue : @dropdownPrefix

    source = @getOptions().dataSource
    source args, callback

  # Overriden to prevent clearing the input.
  appendAutoCompletedItem: ->

  addItemToSubmitQueue:(item,data)->
    data or= item.getData()
    {itemDataPath, submitValuesAsText} = @getOptions()
    if data
      itemValue = if submitValuesAsText then JsPath.getAt data, itemDataPath else data
    else
      itemValue = item.getOptions().userInput
      data = JsPath itemDataPath, itemValue

    lastWord = @getLastInputWord()
    inputValue = @getView().getValue()

    if @isItemAlreadySelected data
      #inputValue = inputValue.replace lastWord, "@"
    else
      inputValue = inputValue.replace(new RegExp(lastWord+"$"), "@#{itemValue} ")
      @addSelectedItemData data
    
    @getView().setValue inputValue

    @dropdownPrefix = ""

class ChannelLinkView extends KDCustomHTMLView
  constructor: (options = {}, data) ->
    options.tagName or= 'a'
    super options, data

  viewAppended:->    
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    super "{{#(profile.firstName)+' '+#(profile.lastName)}}"

  click: (event) ->
    alert "clicked"