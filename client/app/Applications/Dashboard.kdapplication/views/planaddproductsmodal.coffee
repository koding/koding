class GroupPlanAddProductsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title ?= "Add products"

    options.overlay ?= yes

    super options, data

    data = @getData()

    @loader = new KDLoaderView { size: 14 }

    @addSubView @loader
    @loader.show()

    @planExplanation = new KDCustomHTMLView
      cssClass: 'modalformline'
      partial:
        """
        <h2>Plan</h2>
        """

    @planView = new GroupProductView
      cssClass: 'modalformline'
      tagName: 'div'
    , data

    @productsExplanation = new KDCustomHTMLView
      cssClass: 'modalformline'
      partial:
        """
        <h2>Products</h2>
        <p>Add some products to this plan</p>
        """

    @products = new KDListViewController
      itemClass: GroupAddProductListItem

    @buttonField = new KDView
      cssClass: "formline button-field clearfix"

    @buttonField.addSubView new KDButtonView
      title: 'Save'
      cssClass: 'modal-clean-green'

    @buttonField.addSubView new KDButtonView
      title: 'cancel'
      cssClass: 'modal-cancel'

    @addSubView @planExplanation
    @addSubView @planView
    @addSubView @productsExplanation
    @addSubView @products.getView()
    @addSubView @buttonField


  setProducts: (products) ->
    @loader.hide()

    plan = @getData()

    for product in products
      qty = plan.quatities?[product.planCode] ? 0
      item = @products.addItem product
      item.setQuantity qty