class InboxMessageListController extends KDListViewController
  
  constructor:()->
    super
    @selectedMessages = {}
  
  loadMessages:->
    {currentDelegate} = KD.getSingleton('mainController').getVisitor()
    controller = @
    currentDelegate.fetchMail? (err, messages, participantsInfo)->
      controller.instantiateListItems messages