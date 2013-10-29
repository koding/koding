class GroupProductsController extends KDController

  constructor: (options = {}, data) ->
    super options, data

    @prepareProductView 'Product'
    @prepareProductView 'Plan'

  prepareProductView: (category) ->
    { view } = @getOptions()
    group = KD.getGroup()
    konstructor = getConstructor category

    reload = ->
      group["fetch#{ category }s"] (err, results) ->
        view["set#{ category }s"] results

    handleResponse = (err) ->
      return if KD.showError err

      reload()

    view.on "#{ category }BuyersReportRequested", ->
      debugger # needs to be implemented

    view.on "#{ category }DeleteRequested", (data) ->
      confirmDelete data, ->
        konstructor.removeByCode data.planCode, handleResponse

    view.on "#{ category }EditRequested", (data) ->
      options = getProductFormOptions category

      showEditModal options, data, (err, model, productData) ->
        return if KD.showError err

        if model
          model.modify productData, handleResponse
        else
          konstructor.create productData, handleResponse

    reload()

  confirmDelete = (data, callback) ->

    productViewOptions =
      tagName   : 'div'
      cssClass  : 'modalformline'

    productView = new GroupProductView productViewOptions, data

    modal = KDModalView.confirm
      title       : "Warning"
      description : "Are you sure you want to delete this item?"
      subView     : productView
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

    createForm.on 'CancelRequested', ->
      modal.destroy()

    createForm.on 'SaveRequested', (model, productData) ->
      modal.destroy()

      callback null, model, productData

  getProductFormOptions = (category) ->
    switch category

      when 'Product'
        productType         : 'product'
        isRecurOptional     : yes
        showOverage         : yes
        showSoldAlone       : yes
        showPriceIsVolatile : yes

      when 'Plan'
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
