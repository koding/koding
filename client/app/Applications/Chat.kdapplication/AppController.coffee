class ChatAppController extends AppController

  KD.registerAppClass @,
    name         : "Chat"
    route        : "Chat"
    background   : yes

  constructor:(options, data)->
    super options, data

    notificationController = KD.getSingleton 'notificationController'
    notificationController.on 'chatRequest', @bound 'handleChatRequest'

  handleChatRequest:->
    console.log 'this is a stub' # TODO: implement