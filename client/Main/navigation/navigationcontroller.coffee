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
    if item = @getItemByName name
    then @selectItem item
    else @deselectAllItems()
    return item

  removeItemByTitle:(name)->
    for navItem in @itemsOrdered when navItem?.name is name
      @removeItem navItem

  instantiateListItems:(items)->
    {roles} = KD.config

    for itemData in items
      # if not defined, do not check loggedIn state
      if itemData.loggedIn?
        # loggedIn:yes = do not show if not logged in
        if itemData.loggedIn
          continue  unless KD.isLoggedIn() # do not show if not logged in
        # loggedIn:no = do not show if logged in
        unless itemData.loggedIn
          continue  if     KD.isLoggedIn()

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
