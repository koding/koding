class ChatMessageListController extends CommonChatController

  constructor:->
    super
    @me = KD.whoami().profile.nickname

  addItem:(data)->
    if data.sender is @me then data.cssClass = 'mine'
    super data