kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListViewController = kd.ListViewController
module.exports = class ProductSectionListController extends KDListViewController

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message


