class InboxMessageListController extends KDListViewController

  constructor:()->
    super
    @selectedMessages = {}

  loadMessages:(callback)->
    @removeAllItems()
    KD.whoami().fetchMail
      limit       : 10
      sort        :
        timestamp : -1
    , (err, messages)=>
      @instantiateListItems messages
      callback?()