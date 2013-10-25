class GroupProductSettingsView extends JView

  constructor: (options = {}, data) ->
    super options, data

    @setClass 'group-product-section'

    @productsView = new GroupProductsView

    @forwardEvent @productsView, 'DeleteRequested', 'Product'

    @productsView.on 'CreateRequested', =>
      @showCreateModal
        productType       : 'product'
        isOverageEnabled  : yes

    @plansView = new GroupPlansView

    @plansView.on 'CreateRequested', =>
      @showCreateModal
        productType         : 'plan'
        isRecurringOptional : no
        isOverageEnabled    : no
        placeholders        :
          title             : 'e.g. "Gold Plan"'
          description       : 'e.g. "2 VMs, and a tee shirt"'

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
    @productsView.setProducts products

  setPlans: (plans) -> console.log 'need to set the plans', plans

  pistachio: ->
    """
    {{> @productsView}}
    {{> @plansView}}
    """