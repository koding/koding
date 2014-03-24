class GroupProductsController extends KDController

  { dash } = Bongo

  constructor: (options = {}, data) ->
    super options, data

    @productsView = @prepareProductView 'product'
    @packsView    = @prepareProductView 'pack'
    @plansView    = @prepareProductView 'plan'

  prepareProductView: (category) ->
    { view } = @getOptions()

    konstructor = getConstructor category

    do reload = =>
      @fetchProducts category, (err, products) ->
        view.setProducts category, products

    handleResponse = (err) ->
      return  if KD.showError err

      reload()

    handleEdit = (data) ->
      options = getProductFormOptions category

      showEditModal options, data, (err, model, productData) ->
        return  if KD.showError err

        if model
          model.modify productData, handleResponse
        else
          konstructor.create productData, handleResponse

    showAddProductsModal = (plan) =>
      modal = new GroupPlanAddProductsModal {}, plan
      modal.on 'ProductsAdded', (quantities) ->
        plan.updateProducts quantities, (err) ->
          handleResponse err

          modal.destroy()

      @fetchProducts 'product', (err, products) ->
        return  if KD.showError err

        modal.setProducts products

    categoryView = view.getCategoryView category

    categoryView

      .on("CreateRequested", handleEdit)

      .on("EditRequested", handleEdit)

      .on("AddProductsRequested", showAddProductsModal)

      .on "DeleteRequested", (data) ->
        confirmDelete data, ->
          konstructor.removeByCode data.planCode, handleResponse

      .on "BuyersReportRequested", (data) ->
        debugger # needs to be implemented

  confirmDelete = (data, callback) ->

    productViewOptions =
      tagName   : 'div'
      cssClass  : 'modalformline'

    modal = KDModalView.confirm
      title       : "Warning"
      description : "Are you sure you want to delete this item?"
      subView     : new GroupProductView productViewOptions, data
      ok          :
        title     : "Remove"
        callback  : ->
          modal.destroy()
          callback()

  showEditModal = (options, data, callback) ->
    productType = options.productType ? 'product'

    formConstructor = options.formClass ? GroupProductEditForm

    modal = new KDModalView
      overlay       : yes
      title         : "Create #{ productType }"

    createForm = new formConstructor options, data

    modal.addSubView createForm

    createForm

      .on('CancelRequested', modal.bound 'destroy')

      .on 'SaveRequested', (model, productData) ->
        modal.destroy()

        callback null, model, productData

  getProductFormOptions = (category) ->
    switch category

      when 'product'
        productType         : 'product'
        isRecurOptional     : yes
        showOverage         : yes
        showSoldAlone       : yes
        showPriceIsVolatile : yes

      when 'pack'
        productType         : 'pack'
        formClass           : GroupPackEditForm
        isRecurOptional     : no
        showOverage         : no
        showSoldAlone       : no
        showPriceIsVolatile : no
        placeholders        :
          title             : "VM — extra large"
          description       : "4 cores, 4 GB RAM, 8 GB disk"

      when 'plan'
        productType         : 'plan'
        isRecurOptional     : no
        showOverage         : no
        showSoldAlone       : no
        showPriceIsVolatile : yes
        canApplyCoupon      : yes
        placeholders        :
          title             : 'e.g. "Gold Plan"'
          description       : 'e.g. "2 VMs, and a tee shirt"'

  getConstructor = (category) -> switch category
    when 'product'
      KD.remote.api.JPaymentProduct
    when 'pack'
      KD.remote.api.JPaymentPack
    when 'plan'
      KD.remote.api.JPaymentPlan

  fetchProducts: (category, callback) ->
    KD.getGroup().fetchProducts category, (err, products) ->
      return callback err  if err
      products = products.filter (plan)-> not ("kite" in plan.tags)
      queue = products.map (plan) -> ->
        # recursively fetch nested products, if any
        if plan.fetchProducts?
          plan.fetchProducts (err, planProducts) ->
            return queue.fin err  if err

            plan.childProducts = planProducts
            queue.fin()

        else queue.fin()

      dash queue, (err) ->
        return callback err  if err

        callback null, products
