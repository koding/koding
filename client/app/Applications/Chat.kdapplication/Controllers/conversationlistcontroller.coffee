class ChatConversationListController extends CommonChatController

  constructor:->
    super
    @getListView().on 'moveToIndexRequested', @bound 'moveItemToIndex'

  addItem:(data)->
    # Make sure there is one conversation with same channel name
    {chatChannel} = data
    for chat in @itemsOrdered
      return  if chat.conversation?.channel?.name is chatChannel?.name
    super data
