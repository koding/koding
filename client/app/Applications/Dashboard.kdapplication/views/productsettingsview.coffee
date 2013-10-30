class GroupProductSettingsView extends JView

  constructor: (options = {}, data) ->
    super options, data

    @setClass 'group-product-section'

    @productsView = new GroupProductSectionView
      category  : 'product'
      itemClass : GroupProductListItem
      pistachio :
        """
        <h2>Products</h2>
        {{> @createButton}}
        {{> @list}}
        """

    @productsView.on 'CreateRequested', =>
      @emit 'EditRequested'

    @plansView = new GroupProductSectionView
      category  : 'plan'
      itemClass : GroupPlanListItem
      pistachio :
        """
        <h2>Plans</h2>
        <p>Plans are bundles of products.  Effectively, the quantities
           you choose will serve as maximum quantities per plan.</p>
        {{> @createButton}}
        {{> @list}}
        """

    @plansView.on 'CreateRequested', =>
      @emit 'EditRequested'

    ['product', 'plan'].forEach (category) =>
      @forwardEvents @["#{category}sView"], [
        'DeleteRequested'
        'EditRequested'
        'BuyersReportRequested'
      ]

  getCategoryView: (category) -> @["#{ category }sView"]

  setProducts: (category, contents) ->
    view = @getCategoryView category
    view.setContents contents

  pistachio: ->
    """
    {{> @productsView}}
    {{> @plansView}}
    """