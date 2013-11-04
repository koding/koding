class GroupPlanListItem extends GroupProductListItem
  viewAppended: ->
    plan = @getData()

    @planView = new GroupProductView {}, plan

    @addProductsButton = new KDButtonView
      title    : "Add products"
      callback : => @emit 'AddProductsRequested', plan

    @childProducts = new KDListViewController
      itemClass : GroupChildProductListItem

    if plan.childProducts?

      @childProducts.instantiateListItems(
        plan.childProducts.map (product) ->
          {
            product
            quantity: plan.quantities[product.planCode]
          }
      )

    super()

  pistachio:->
    """
    {{> @planView}}
    {{> @embedButton}}
    {{> @deleteButton}}
    {{> @clientsButton}}
    {{> @editButton}}
    {{> @addProductsButton}}
    {{> @childProducts.getView()}}
    {{> @embedView}}
    """
