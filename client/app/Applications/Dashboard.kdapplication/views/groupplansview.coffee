class GroupPlansView extends JView

  viewAppended: ->
    @setClass 'group-product-section'

    @createButton = new KDButtonView
      cssClass    : "cupid-green"
      title       : "Create a plan"
      callback    : =>
        @emit 'CreateRequested'

    super()

  pistachio:->
    """
    <h2>Plans</h2>
    <p>Plans are bundles of products.  Effectively, the quantities you choose will serve as maximum quantities per plan.</p>
    {{> @createButton}}
    """