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

  removeItemByTitle:(name)->
    for navItem in @itemsOrdered when navItem?.name is name
      @removeItem navItem

  instantiateListItems:(items)->
    {roles} = KD.config

    newItems = for itemData in items
      if itemData.role
        if itemData.role in roles
          @getListView().addItem itemData
      else
        @getListView().addItem itemData


class MainNavController extends NavigationController

  reset:->
    previousSelection = @selectedItems.slice()
    @removeAllItems()
    @instantiateListItems KD.getNavItems()
    @selectItemByName name  for {name} in previousSelection
