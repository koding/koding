class GroupProductListController extends KDListViewController

  constructor:(options = {}, data)->
    @group = options.group
    super

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message

