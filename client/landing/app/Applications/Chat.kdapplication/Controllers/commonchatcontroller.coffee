class CommonChatController extends KDListViewController

  constructor:->
    super
    @me = KD.whoami()

  loadView:->
    super
    list = @getListView()
    @loadItems()

  loadItems:(callback)->
    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message