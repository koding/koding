class ChatConversationListController extends CommonChatController

  constructor:->
    super
    @getListView().on 'moveToIndexRequested', @bound 'moveItemToIndex'

  # loadItems:(callback)->
  #   super

  #   @me.fetchFollowersWithRelationship {}, {}, (err, accounts)=>
  #     @instantiateListItems accounts unless err
