class GroupProductsView extends JView

  constructor: (options = {}, data) ->
    super options, data

    group = @getData()

    @setClass "payment-settings-view"

    @createButton = new KDButtonView
      cssClass    : "cupid-green"
      title       : "Create a product"
      callback    : =>
        @emit 'CreateRequested'

    @productListController = new GroupProductListController
      group     : group
      itemClass : GroupProductListItem

    @list = @productListController.getListView()

    @list.on "DeleteItem", (code) =>
      @emit 'DeleteRequested', code

  resetForm: ->
    @productCreateForm.reset()

  setProducts: (products) ->
    @productListController.removeAllItems()
    @productListController.instantiateListItems products

  pistachio: ->
    """
    <h2>Products</h2>
    {{> @createButton}}
    {{> @productListController.getView()}}
    """