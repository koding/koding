class NavigationController extends KDListViewController

  reset:->
    previousSelection = @selectedItems.slice()
    @removeAllItems()
    @instantiateListItems @getData().items
    @selectItemByName name  for {name} in previousSelection

  getItemByName:(name)->
    for navItem in @itemsOrdered when navItem.getData()?.title is name
      return navItem

  selectItemByName:(name)->
    @selectItem item  if item = @getItemByName name
    return item

  instantiateListItems:(items)->

    newItems = for itemData in items
      if KD.isLoggedIn()
        continue if itemData.loggedOut
      else
        continue if itemData.loggedIn
      @getListView().addItem itemData

  removeItemByTitle:(name)->
    for navItem in @itemsOrdered when navItem?.name is name
      @removeItem navItem
