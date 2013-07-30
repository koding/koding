class ChatAppController extends AppController

  KD.registerAppClass this,
    name         : "Chat"
    route        : "/:name?/Chat"
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

  leave:({conversation, chatChannel}, callback)->
    content = """ When you leave conversation you will not
                  receive any messages. And you will also loose
                  current messages in this conversation.
                  Do you want to continue? """

    modal = new KDModalView
      title          : "Do you want to leave this conversation?"
      content        : "<div class='modalformline'><p>#{content}</p></div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        'Leave'      :
          style      : "modal-clean-red"
          callback   : =>
            chatChannel?.close()?.off()
            conversation.leave (err)=>
              warn err  if err
              modal.destroy()
              callback?()
        Cancel       :
          style      : "modal-clean-gray"
          callback   : ->
            modal.destroy()

class ChannelWrapper extends KDObject
  constructor:(@channel)-> super {}
  sendMessage:(message) -> @channel.publish JSON.stringify message
