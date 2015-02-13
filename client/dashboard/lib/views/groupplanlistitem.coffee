kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListView = kd.ListView
KDListViewController = kd.ListViewController
GroupChildProductListItem = require './groupchildproductlistitem'
GroupProductListItem = require './groupproductlistitem'
GroupProductView = require './groupproductview'


module.exports = class GroupPlanListItem extends GroupProductListItem
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


