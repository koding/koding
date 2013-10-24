class GroupProductSettingsView extends JView

  constructor: (options = {}, data) ->
    super options, data

    group = @getData()

    @setClass "payment-settings-view"

    @productCreateForm = new GroupProductCreateForm

    @forwardEvent @productCreateForm, 'ProductCreateRequested'

    @reloadButton = new KDButtonView
      cssClass   : "product-button"
      title      : "Reload"
      callback   : =>
        @emit 'ProductReloadRequested'

    @productListController = new GroupProductListController
      group     : group
      itemClass : GroupProductListItem
    # @controller.loadItems()

    @list = @productListController.getListView()
    @list.on "DeleteItem", (code)=>
      group.deleteProduct {code}, =>
        @emit 'ProductReloadRequested'

  setProducts: (products) ->
    @productListController.instantiateListItems products

  pistachio: ->
    """
    {{> @productCreateForm}}
    {{> @reloadButton}}
    {{> @productListController.getView()}}
    """