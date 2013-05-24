class NavigationController extends KDListViewController

  reset:->
    previousSelection = @selectedItems.slice()
    @removeAllItems()
    @instantiateListItems @getData().items
    @selectItemByName name  for {name} in previousSelection

  selectItemByName:(name)->
    item = no
    for navItem in @itemsOrdered when navItem.name is name
      @selectItem item = navItem
      break
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
