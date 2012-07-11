class InboxMessageListController extends KDListViewController
  
  constructor:()->
    super
    @selectedMessages = {}
  
  loadMessages:->
    {currentDelegate} = KD.getSingleton('mainController').getVisitor()
    controller = @
    debugger
    currentDelegate.fetchMail? (err, messages, participantsInfo)->
      controller.instantiateListItems messages

  instantiateListItems:(items)->
    listView = @getListView()
    items.forEach (itemModel) =>
      itemView = listView.itemClass delegate : listView,itemModel
      itemView.registerListener KDEventTypes : 'click', listener : @, callback : listView.itemClicked

      @itemsOrdered[if @getOptions().lastToFirst then 'unshift' else 'push'] itemView
      @itemsIndexed[itemView.getItemDataId()] = itemView
      listView.appendItem itemView
      itemView