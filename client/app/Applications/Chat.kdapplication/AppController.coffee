class ChatAppController extends AppController

  KD.registerAppClass @,
    name         : "Chat"
    route        : "Chat"
    background   : yes

  constructor:(options, data)->
    super options, data

    notificationController = KD.getSingleton 'notificationController'
    notificationController.on 'chatRequest', @bound 'handleChatRequest'
    notificationController.on 'chatRoomOpen', @bound 'handleChatRoomOpen'

  handleChatRoomOpen:({publishingToken, subscriptionToken})->


  create:(invitees, callback)->
    {JChatConversation} = KD.remote.api
    JChatConversation.create invitees, (err, chatConversation)=>
      return callback err  if err
      chatChannel = @subscribe chatConversation.publicName
      callback null, chatChannel

  subscribe:(publicName)->
    options = { serviceType: 'chat', isP2P: yes, exchange: 'chat' }
    channel = KD.remote.subscribe publicName, options
    channel.on 'message', @bound 'handleChatMessage'

  handleChatRequest:(request)->
    {invitee, publicName} = request

    if invitee isnt KD.whoami().profile.nickname
      throw new Error 'Red alert!  Security breach detected!'

    chatChannel = @subscribe publicName

    console.log {chatChannel}
  
  handleChatMessage:-> console.log arguments