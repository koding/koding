class GroupPlanListItem extends GroupProductListItem
  viewAppended: ->
    plan = @getData()

    @planView = new GroupProductView {}, plan

    @childProducts = new KDListViewController
      view        : new KDListView
        cssClass  : 'plan-child-products'
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
    <div class="product-item">
      {{> @planView}}
      {{> @controls}}
      <h3>Contains:</h3>
      {{> @childProducts.getView()}}
    </div>
    """
