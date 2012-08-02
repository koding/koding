class InboxMessageListController extends KDListViewController

  constructor:()->
    super
    @selectedMessages = {}

  loadMessages:(callback)->
    @removeAllItems()
    @utils.wait 7000, => callback?()
    KD.whoami().fetchMail
      limit       : 20
      sort        :
        timestamp : -1
    , (err, messages)=>
      @instantiateListItems messages
      callback?()