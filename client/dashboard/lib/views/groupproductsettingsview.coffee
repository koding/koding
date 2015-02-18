GroupPlanListItem = require './groupplanlistitem'
GroupProductListItem = require './groupproductlistitem'
GroupProductSectionView = require './groupproductsectionview'
PlanAdminControlsView = require './planadmincontrolsview'
ProductAdminControlsView = require './productadmincontrolsview'
JView = require 'app/jview'


module.exports = class GroupProductSettingsView extends JView

  constructor: (options = {}, data) ->
    super options, data

    @setClass 'group-product-section'

    @productsView = new GroupProductSectionView
      category      : 'product'
      itemClass     : GroupProductListItem
      controlsClass : ProductAdminControlsView
      pistachio     :
        """
        <h2>Products</h2>
        {{> @createButton}}
        {{> @list}}
        """

    @packsView = new GroupProductSectionView
      category      : 'pack'
      itemClass     : GroupPlanListItem
      controlsClass : PlanAdminControlsView
      pistachio     :
        """
        <h2>Packs</h2>
        <p>Packs are bundles of products, used for representing larger
           products, for instance, a VM with 1 GB of RAM and 2 cores.</p>
        {{> @createButton}}
        {{> @list}}
        """

    @plansView = new GroupProductSectionView
      category      : 'plan'
      itemClass     : GroupPlanListItem
      controlsClass : PlanAdminControlsView
      pistachio     :
        """
        <h2>Plans</h2>
        <p>Plans are bundles of products.  Effectively, the quantities
           you choose will serve as maximum quantities per plan.</p>
        {{> @createButton}}
        {{> @list}}
        """

    ['product', 'pack', 'plan'].forEach (category) =>
      categoryView = @getCategoryView category

      categoryView.on 'CreateRequested', =>
        @emit 'EditRequested'

      @forwardEvents categoryView, [
        'DeleteRequested'
        'EditRequested'
        'AddProductsRequested'
        'BuyersReportRequested'
      ]

  getCategoryView: (category) -> @["#{ category }sView"]

  setProducts: (category, contents) ->
    view = @getCategoryView category
    view.setContents contents

  pistachio: ->
    """
    {{> @productsView}}
    {{> @packsView}}
    {{> @plansView}}
    """

