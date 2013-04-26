class ChatAppController extends AppController

  KD.registerAppClass @,
    name         : "Chat"
    route        : "Chat"
    background   : yes

  constructor:(options, data)->
    super options, data

    notificationController = KD.getSingleton 'notificationController'
    notificationController.on 'chatRequest', @bound 'handleChatRequest'

  create:(invitees, callback)->
    chatPanel = KD.getSingleton 'chatPanel'
    {JChatConversation} = KD.remote.api
    JChatConversation.create invitees, (err, conversation)=>
      return callback err  if err
      chatChannel = @subscribe conversation.publicName
      chatPanel.createConversation {chatChannel, conversation, invitees}
      callback null, new ChannelWrapper chatChannel

  subscribe:(publicName)->
    options = { serviceType: 'chat', isP2P: yes }
    return KD.remote.subscribe publicName, options

  handleChatRequest:(request)->
    {invitee, publicName} = request

    if invitee isnt KD.whoami().profile.nickname
      throw new Error 'Red alert!  Security breach detected!'

    chatPanel = KD.getSingleton 'chatPanel'
    chatChannel = @subscribe publicName

    {JChatConversation} = KD.remote.api
    JChatConversation.fetch publicName, (err, conversation)=>
      chatPanel.createConversation {chatChannel, conversation}

class ChannelWrapper extends KDObject

  constructor:(@channel)->
    super
    @me = KD.whoami().profile.nickname

  sendMessage:(message)->
    @channel.publish JSON.stringify
      sender  : @me
      message : message
