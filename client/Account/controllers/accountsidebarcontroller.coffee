class AccountSideBarController extends KDViewController
  constructor:(options, data)->
    options.view = new KDView domId : options.domId
    super options, data

  loadView:(mainView)->
    allNavItems = []
    for controller in @sectionControllers
      allNavItems = allNavItems.concat controller.itemsOrdered

    @allNavItems = allNavItems

    @setActiveNavItem 0

  setActiveNavItem:(index)->
    sectionControllers = @sectionControllers
    totalIndex    = 0
    controllerIndex = 0
    while index >= totalIndex
      activeNavController = sectionControllers[controllerIndex]
      controllerIndex++
      totalIndex += activeNavController.itemsOrdered.length

    activeNavItem = @allNavItems[index]

    @unselectAllNavItems activeNavController
    activeNavController.selectItem activeNavItem

  unselectAllNavItems:(clickedController)->
    for controller in @sectionControllers
      controller.deselectAllItems() unless clickedController is controller
