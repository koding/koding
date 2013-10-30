class GroupPlanAddProductsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title ?= "Add products"

    super options, data

    data = @getData()

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

    @addSubView @planExplanation
    @addSubView @planView
    @addSubView @productsExplanation

  setContents: (contents) -> debugger
