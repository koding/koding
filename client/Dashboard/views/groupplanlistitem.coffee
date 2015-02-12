class GroupPlanListItem extends GroupProductListItem
  viewAppended: ->
    plan = @getData()

    @planView = new GroupProductView {}, plan

    @childProducts = new KDListViewController
      view        : new KDListView
        cssClass  : 'plan-child-products'
        itemClass : GroupChildProductListItem

    @details = new KDCustomHTMLView cssClass : 'hidden'

    if plan.childProducts.length

      @details = @childProducts.getView()
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
      {{> @details}}
      {{> @controls}}
    </div>
    """
