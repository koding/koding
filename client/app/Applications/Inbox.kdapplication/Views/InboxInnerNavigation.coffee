class InboxInnerNavigation extends CommonInnerNavigation
  viewAppended:->
    @viewController = viewController = @setListController {},@menuData
    @addSubView viewListWrapper = viewController.getView()

    viewItemToBeSelected = viewController.getItemsOrdered()[0]
    viewController.selectItem viewItemToBeSelected

    # setTimeout =>
    #   @emit "NavItemReceivedClick", viewItemToBeSelected.getData()
    # ,10

    @addSubView helpBox = new HelpBox
      subtitle    : "About Your Inbox"
      tooltip     :
        title     : "<p class=\"bigtwipsy\">The Inbox displays messages from the people on Koding, as well as notifications received when people comment on items you have posted. It's also a place where you can contact people in the community, or respond to messages you receive. </p>"
        placement : "above"
        offset    : 0
        delayIn   : 300
        html      : yes
        animate   : yes


  menuData :
    title : "VIEW"
    items : [
        { title : "Messages",         type : "messages",       action : "change-tab" }
        { title : "Notifications",    type : "notifications",  action : "change-tab" }
        # { title : "Follows",          type : "code",           action : "change-tab", disabledForBeta : yes }
        # { title : "Chat History",     type : "qa",             action : "change-tab", disabledForBeta : yes }
      ]

  selectNavTab:(tabName)->
    # log @viewController
    return unless @viewController
    itemToBeSelected = null
    for item in @viewController.itemsOrdered
      if item.getData().type is tabName
        itemToBeSelected = item

    if itemToBeSelected
      @viewController.selectItem itemToBeSelected

