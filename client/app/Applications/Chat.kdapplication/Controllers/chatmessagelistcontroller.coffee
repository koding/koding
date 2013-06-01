class ChatMessageListController extends CommonChatController

  addItem:(event, message)->
    log "HERE", event, message

    # if data.sender is @me then data.cssClass = 'mine'
    # super data