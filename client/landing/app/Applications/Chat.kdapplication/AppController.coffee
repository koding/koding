###
The main controller to keep track of channels the current client
are in, handling the communication between the ChatView and each
Channel instance.
###
class Chat12345 extends AppController
  {mq} = bongo

  constructor:(options = {}, data)->
    options.view = new ChatView
      cssClass : "content-page chat"

    super options, data

    @account = KD.whoami()
    @username = @account?.profile?.nickname
    @username = "Guest"+__utils.getRandomNumber() if @username is "Guest"

    @channels = {}
    @broadcaster = mq.subscribe "private-KDPublicChat"

    # Presence received has format [name, "bind" || "unbind"]
    mq.presence @username, ([name, status]) =>
      if status is "bind"
        @addOnlineUser name, 'public'
      else if status is "unbind"
        @removeOfflineUser name, 'public'

  bringToFront:()->
    super name : 'Chat'#, type : 'background'

  loadView:(mainView)->
    @joinChannel 'public'

  joinChannel: (name) ->
    view = @getOptions().view
    channelPaneInstance = view.addChannelTab name
    channelName = "client-#{name}"

    channel = new Channel 
      name: name
      view: channelPaneInstance

    channel.view.on "ChatMessageSent", (messageBody) =>
      chatItem = 
        author: @username
        body: messageBody
        meta: {createdAt: new Date()}

      @broadcaster.emit channelName, JSON.stringify(chatItem)
      chatItem.author = "me"
      channel.messageReceived chatItem

    @channels[name] = channel
    @broadcaster.on channelName, (msg) ->
      channel.messageReceived msg

  addOnlineUser: (name, channelName) ->
    channel = @channels[channelName]
    userItemViewInstance = channel.addOnlineUser name
    return if name is @username
    userItemViewInstance.registerListener
      KDEventTypes: 'click'
      listener    : @
      callback    : =>
        @joinChannel name

  removeOfflineUser: (name, channelName) ->
    channel = @channels[channelName]
    channel.removeOfflineUser name

class Channel extends KDEventEmitter
  constructor: (options = {}, data) ->
    @account = KD.whoami()
    @username = @account?.profile?.nickname
    @username = "Guest"+__utils.getRandomNumber() if @username is "Guest"
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
      items: [
        {name: "erlang", status: "99 online"}
        {name: "nodejs", status: "10 online"}
        {name: "python", status: "25 online"}
      ]

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
      <span class="author-wrapper">{{#(author)}}</span>
      <span class='time'>{{$.timeago #(meta.createdAt)}}</span>
    </div>
    <div>{{#(body)}}</div>
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