class ActivityInnerNavigation extends CommonInnerNavigation

  viewAppended:->

    filterController = @setListController
      type: "filterme"
      itemClass: CommonInnerNavigationListItem
    , @filterMenuData

    @addSubView filterController.getView()
    filterController.selectItem filterController.getItemsOrdered().first

    KD.getSingleton('mainController').on "AccountChanged", (account)=>
      filterController.reset()
      filterController.selectItem filterController.getItemsOrdered()[0]

  filterMenuData :
    title: 'FILTER'
    items: [
      {title: "Public",    type: "Public" },
      {title: "Following", type: "Followed", role: "member" }
    ]
