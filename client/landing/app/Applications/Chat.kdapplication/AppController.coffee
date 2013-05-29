class ChatAppController extends AppController

  KD.registerAppClass this,
    name         : "Chat"
    route        : "Chat"
    background   : yes

  constructor:(options, data)->
    super options, data

    notificationController = KD.getSingleton 'notificationController'
    notificationController.on 'chatRequest', @bound 'handleChatRequest'
    notificationController.on 'chatOpen', @bound 'handleChatOpen'

    @channels       = {}
    @conversations  = {}

  handleChatOpen:({routingKey, bindingKey, publicName})->
    channel = KD.remote.mq.setP2PKeys publicName, { routingKey, bindingKey }, 'secret'

  create:(invitees, callback)->
    chatPanel = KD.getSingleton 'chatPanel'
    {JChatConversation} = KD.remote.api
    JChatConversation.create invitees, (err, conversation)=>
      return callback err  if err
      chatChannel = @subscribe conversation.publicName
      callback null, new ChannelWrapper chatChannel

  subscribe:(publicName)->
    options = { serviceType: 'chat', isP2P: yes, exchange: 'chat' }
    channel = KD.remote.subscribe publicName, options
    channel.on 'message', @bound 'handleChatMessage'

  handleChatRequest:(request, callback)->
    {invitee, publicName} = request

    if invitee isnt KD.whoami().profile.nickname
      throw new Error 'Red alert!  Security breach detected!'

    chatPanel = KD.getSingleton 'chatPanel'
    chatChannel = @subscribe publicName

    @channels[publicName] = chatChannel

    {JChatConversation} = KD.remote.api
    JChatConversation.fetch publicName, (err, conversation)=>
      chatPanel.createConversation {chatChannel, conversation}

    callback? null, chatChannel

  handleChatMessage: -> console.log arguments

class ChannelWrapper extends KDObject

  constructor:(@channel)->
    super
    @me = KD.whoami().profile.nickname

  sendMessage:(message)->
    @channel.publish JSON.stringify
      sender  : @me
      message : message