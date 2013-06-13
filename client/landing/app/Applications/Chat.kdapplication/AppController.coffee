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

    @channels = {}

  handleChatOpen:({routingKey, bindingKey, publicName})->
    channel = KD.remote.mq.setP2PKeys \
      publicName, { routingKey, bindingKey }, 'secret'
    @channels[publicName] = channel  if channel?

  create:(invitees, callback)->
    chatPanel = KD.getSingleton 'chatPanel'
    {JChatConversation} = KD.remote.api
    JChatConversation.create invitees, (err, conversation)=>
      return callback err  if err
      chatChannel = @subscribe conversation.publicName
      callback null, new ChannelWrapper chatChannel

  subscribe:(publicName)->
    chatChannel = KD.remote.subscribe publicName,
      serviceType : 'chat'
      exchange    : 'chat'
      isP2P       : yes
    @channels[publicName] = chatChannel

  handleChatRequest:(request, callback)->
    {invitee, publicName} = request

    if invitee isnt KD.nick()
      throw new Error 'Red alert!  Security breach detected!'

    @addConversationToChatPanel publicName

  addConversationToChatPanel:(publicName, conversation)->
    @subscribe publicName
    chatPanel = KD.getSingleton 'chatPanel'

    if conversation
      chatChannel = @channels[publicName]
      chatPanel.createConversation {chatChannel, conversation}
    else
      {JChatConversation} = KD.remote.api
      JChatConversation.fetch publicName, (err, conversation)=>
        chatChannel = @channels[publicName]
        chatPanel.createConversation {chatChannel, conversation}

class ChannelWrapper extends KDObject
  constructor:(@channel)-> super {}
  sendMessage:(message) -> @channel.publish JSON.stringify message
