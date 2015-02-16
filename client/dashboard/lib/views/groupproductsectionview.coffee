kd = require 'kd'
KDButtonView = kd.ButtonView
ProductSectionListController = require './productsectionlistcontroller'
JView = require 'app/jview'


module.exports = class GroupProductSectionView extends JView

  viewAppended: ->
    { category, itemClass, controlsClass } = @getOptions()

    @setClass "payment-settings-view"

    @createButton = new KDButtonView
      cssClass    : "cupid-green"
      title       : "Create a #{ category }"
      callback    : =>
        @emit 'CreateRequested'

    @listController = new ProductSectionListController { itemClass }

    @list = @listController.getListView()

    if controlsClass
      @list.on "ItemWasAdded", (item) =>
        controls = new controlsClass {}, item.getData()
        item.setControls controls
        @forwardEvents controls, [
          'DeleteRequested'
          'EditRequested'
          'AddProductsRequested'
          'BuyersReportRequested'
        ]

    super()

  setContents: (contents) ->
    @listController.removeAllItems()
    @listController.instantiateListItems contents


