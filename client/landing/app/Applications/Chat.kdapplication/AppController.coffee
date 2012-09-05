###
The main controller to keep track of channels the current client
are in, handling the communication between the ChatView and each
Channel instance.
###
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

  joinChannel: (name) ->
    return @channels[name] if @channels[name]

    view = @getOptions().view
    channelPaneInstance = view.addChannelTab name
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

    channel.view.on "ChatMessageSent", (messageBody) =>
      @parseMessageForChannels messageBody
      @broadcastOwnMessage channel, messageBody
      if name isnt PUBLIC
        @broadcastOwnMessage @channels[PUBLIC], messageBody

    @broadcaster.on channelName, (msg) ->
      channel.messageReceived msg

    @channels[name] = channel

  parseMessageForChannels: (message) ->
    topicExp = /#([\w-]+)/g
    while match = topicExp.exec message
      channelName = match[1]
      channel = @joinChannel channelName
      @broadcastOwnMessage channel, message

  broadcastOwnMessage: (channel, messageBody) ->
    chatItem = 
      author: @username
      body: messageBody
      meta: {createdAt: new Date()}

    channelMQName = "client-#{channel.name}"
    @broadcaster.emit channelMQName, JSON.stringify(chatItem)
    chatItem.author = "me"
    channel.messageReceived chatItem

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
    message.channel = @name
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
    """
    <div class='meta'>      
      <span class='time'>[{{#(meta.createdAt)}}] </span>
      <span class="author-wrapper">[{{#(author)}}]: </span>
      <span>{{#(body)}}</span>
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