class CommonChatController extends KDListViewController

  loadView:->
    super
    @loadItems()

  loadItems:(callback)->
    @removeAllItems()
    @customItem?.destroy()

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message