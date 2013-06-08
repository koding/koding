class ChatConversationListController extends CommonChatController

  constructor:->
    super
    @getListView().on 'moveToIndexRequested', @bound 'moveItemToIndex'

  addItem:(data)->
    # Make sure there is one conversation with same channel name
    {conversation, chatChannel} = data
    for chat in @itemsOrdered
      return  if chat.conversation?.channel?.name is chatChannel?.name

    return  if (conversation.invitees?.length or 1) < 2

    super data

  loadItems:->
    @removeAllItems()

    chatController = KD.getSingleton 'chatController'
    {JChatConversation} = KD.remote.api
    JChatConversation.fetchSome {}, (err, conversations)=>
      warn err  if err
      for conversation in conversations
        chatController.addConversationToChatPanel \
          conversation.publicName, conversation
