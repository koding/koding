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
    @broadcaster.emit 'client-presence', JSON.stringify(@username)
    @broadcaster.on 'client-presence', (username) =>
      console.log "#{username} joined"
      @addOnlineUser name: username, status: "online"

  bringToFront:()->
    super name : 'Chat'#, type : 'background'

  loadView:(mainView)->
    @joinChannel 'public'
    @addOnlineUser name: @username, status: "online"

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

  addOnlineUser: (user) ->
    view = @getOptions().view
    userItemViewInstance = view.addOnlineUser user
    userItemViewInstance.registerListener
      KDEventTypes: 'click'
      listener    : @
      callback    : =>
        @joinChannel user.name

class Channel extends KDEventEmitter
  constructor: (options = {}, data) ->
    @account = KD.whoami()
    @username = @account?.profile?.nickname
    @username = "Guest"+__utils.getRandomNumber() if @username is "Guest"
    @messages = []
    @participants = {}
    @participants[@username] = @account

    @name = options.name
    @view = options.view

  messageReceived: (message) ->
    @messages.push message
    @view.newMessage message

class ChatView extends KDView
  viewAppended: ->
    @chatTabView = new KDTabView
    @rosterTabView = new KDTabView
    
    @addSubView splitView = new KDSplitView
      sizes: ["30%","70%"]
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

    @rosterTabView.addPane new TabPaneViewWithList 
      name: "people"
      unclosable: true
      subItemClass: ChannelListItemView

  addChannelTab: (name) ->
    channelTabPane = @chatTabView.getPaneByName name
    if channelTabPane
      @chatTabView.showPaneByName name
      return channelTabPane

    tabPane = @chatTabView.addPane new ChannelView
      name: name
      listHeight: 500

  addOnlineUser: (userItem) ->
    userPane = @rosterTabView.getPaneByName 'people'
    userPane.addItem userItem

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

class ChannelView extends TabPaneViewWithList
  constructor: (options = {}, data) ->
    options.subItemClass || (options.subItemClass = ChatListItemView)
    super options, data

  viewAppended: ->
    super()
    @addSubView inputForm = new ChatInputForm delegate : @

  newMessage: (message) ->
    @listView.addItem message

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