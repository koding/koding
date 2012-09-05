###
The main controller to keep track of channels the current client
are in, handling the communication between the ChatView and each
Channel instance.
###
TOPICREGEX = /#([\w-]+)/g
MENTIONREGEX = /@([\w-]+)/g

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
    @joinChannel PUBLIC
    @joinChannel "@#{@username}"

  joinChannel: (name) ->
    return @channels[name] if @channels[name]

    view = @getOptions().view
    channelPaneInstance = view.addChannelTab name

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

    # When the channel's view receives chat input, parse the body
    # and broadcast it to corresponding channels.
    channel.view.on "ChatMessageSent", (messageBody) =>
      @parseMessage messageBody, channel
      @broadcastOwnMessage messageBody, channel 
      # Also broadcast to public channel
      if name isnt PUBLIC
        @broadcastOwnMessage messageBody, @channels[PUBLIC], channel

    # Delegates to the channel to handle received message
    @broadcaster.on channelName, (msg) ->
      channel.messageReceived msg

    @channels[name] = channel

  ###
  # Parses the message body for any reference to a channel, then
  # joins the user to that channel. It will then broadcast the 
  # message body to the newly joined channel.
  ###
  parseMessage: (message, fromChannel) ->
    while match = TOPICREGEX.exec message
      channelName = match[0]
      channel = @joinChannel channelName
      @broadcastOwnMessage message, channel, fromChannel

    while match = MENTIONREGEX.exec message
      mention = match[1]
      channel = @joinChannel "@#{mention}"
      @broadcastOwnMessage message, channel, fromChannel

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

    chatItem.channel = fromChannel.name if fromChannel

    channelMQName = "client-#{toChannel.name}"
    @broadcaster.emit channelMQName, JSON.stringify(chatItem)
    chatItem.author = "me"
    toChannel.messageReceived chatItem

class Channel extends KDEventEmitter
  constructor: (options = {}, data) ->
    @messages = []
    @participants = {}
    @name = options.name
    @view = options.view

  addOnlineUser: (name) ->
    viewInstance = @view.addRosterItem {name:name, status: "online"}
    @participants[name] = viewInstance
    viewInstance

  removeOfflineUser: (name) ->
    viewInstance = @participants[name]
    @view.removeRosterItem viewInstance

  messageReceived: (message) ->
    @messages.push message
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

class ChatListItemView extends KDListItemView
  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    parsedBody = @getData().body.replace(TOPICREGEX, "<a href='#'>$&</a>")
    parsedChannel = @getData().channel?.replace(TOPICREGEX, "<a href='#'>$&</a>")

    """
    <div class='meta'>      
      <span class='time'>[{{#(meta.createdAt)}}] </span>
      #{if @getData().channel? then "<span>[#{parsedChannel}]</span>" else ''}
      <span class="author-wrapper">{{#(author)}}: </span>
      <span>#{parsedBody}</span>
    </div>
    """

class ChannelListItemView extends KDListItemView
  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    "<p>{{#(name)}} - {{#(status)}} </p>"

class ChatInputForm extends KDFormView
  viewAppended: ->
    @addSubView @input = new KDInputView
      placeholder: "Click here to reply"
      name: "chatInput"
      cssClass: "fl"
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Reply field is empty..."

    @addSubView @sendButton = new KDButtonView
      title: "Send"
      cssClass: "fl"
      style: "clean-gray inside-button"
      callback: =>
        chatMsg = @input.getValue()

        @input.setValue ""
        @input.blur()
        @input.$().blur()

        @getDelegate().emit 'ChatMessageSent', chatMsg