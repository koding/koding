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
      @showCreateModal
        productType     : 'product'
        isRecurOptional : yes
        showOverage     : yes
        showSoldAlone   : yes

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
      @showCreateModal
        productType     : 'plan'
        isRecurOptional : no
        showOverage     : no
        showSoldAlone   : no
        placeholders    :
          title         : 'e.g. "Gold Plan"'
          description   : 'e.g. "2 VMs, and a tee shirt"'

    ['product', 'plan'].forEach (category) =>
      @forwardEvents @["#{category}sView"], [
        'DeleteRequested'
        'BuyerReportRequested'
      ], category.capitalize()

  showCreateModal: (options) ->

    productType = options.productType ? 'product'

    modal = new KDModalView
      overlay       : yes
      title         : "Create #{ productType }"

    createForm = new GroupProductCreateForm options

    modal.addSubView createForm

    createForm.on 'CancelRequested', ->
      modal.destroy()

    createForm.on 'CreateRequested', (productData) =>
      createEventName = "#{ productType.capitalize() }CreateRequested"
      @emit createEventName, productData
      modal.destroy()

  setProducts: (products) ->
    @productsView.setContents products

  setPlans: (plans) ->
    @plansView.setContents plans

  pistachio: ->
    """
    {{> @productsView}}
    {{> @plansView}}
    """