class InboxMessageListController extends KDListViewController

  constructor:()->
    super
    @selectedMessages = {}

  continueLoadingMessages:(requester)->
    requester?.updatePartial "Loading..."
    KD.whoami().fetchMail
      limit       : 10
      skip        : @getItemCount()
      sort        :
        timestamp : -1
    , (err, messages)=>
      requester?.hide()
      @instantiateListItems messages

      if messages.length >= 10
        @getListView().addItemView new LoadMoreMessagesItem
          delegate : @

  loadMessages:(callback)->
    @removeAllItems()
    KD.whoami().fetchMail
      limit       : 10
      sort        :
        timestamp : -1
    , (err, messages)=>
      @instantiateListItems messages

      if messages.length >= 10
        @getListView().addItemView new LoadMoreMessagesItem
          delegate : @

      callback?()