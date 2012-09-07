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

    channel = new ChannelController 
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