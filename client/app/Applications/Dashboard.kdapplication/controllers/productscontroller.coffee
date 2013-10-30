class GroupProductsController extends KDController

  constructor: (options = {}, data) ->
    super options, data

    @prepareProductView 'product'
    @prepareProductView 'plan'

  prepareProductView: (category) ->
    { view } = @getOptions()

    konstructor = getConstructor category

    do reload = ->
      KD.getGroup().fetchProducts category, (err, results) ->
        view.setProducts category, results

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

    categoryView = view.getCategoryView category

    categoryView

      .on("CreateRequested", handleEdit)

      .on("EditRequested", handleEdit)

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

    modal = new KDModalView
      overlay       : yes
      title         : "Create #{ productType }"

    createForm = new GroupProductEditForm options, data

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

      when 'plan'
        productType         : 'plan'
        isRecurOptional     : no
        showOverage         : no
        showSoldAlone       : no
        showPriceIsVolatile : no
        placeholders        :
          title             : 'e.g. "Gold Plan"'
          description       : 'e.g. "2 VMs, and a tee shirt"'

  getConstructor = (category) ->
    KD.remote.api["JPayment#{ category.capitalize() }"]
