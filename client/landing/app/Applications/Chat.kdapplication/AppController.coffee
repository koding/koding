class ChatAppController extends AppController

  KD.registerAppClass @,
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
    {JChatConversation} = KD.remote.api
    JChatConversation.create invitees, (err, chatConversation)=>
      return callback err  if err

      @handleChatRequest {
        invitee     : KD.whoami().profile.nickname
        publicName  : chatConversation.publicName
      }, callback

  subscribe:(publicName)->
    options = { serviceType: 'chat', isP2P: yes, exchange: 'chat' }
    channel = KD.remote.subscribe publicName, options
    channel.on 'message', @bound 'handleChatMessage'

  handleChatRequest:(request, callback)->
    {invitee, publicName} = request

    if invitee isnt KD.whoami().profile.nickname
      throw new Error 'Red alert!  Security breach detected!'

    chatChannel = @subscribe publicName

    @channels[publicName] = chatChannel

    callback? null, chatChannel

  handleChatMessage:-> console.log arguments