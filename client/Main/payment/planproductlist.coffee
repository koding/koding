class PlanProductListView extends JView
  constructor: (options = {}, data) ->
    super options, data

    {@plan} = @getOptions()

    @quantititesList = new KDListViewController
      startWithLazyLoader    : no
      view                   : new KDListView
        type                 : "products"
        cssClass             : "product-item-list"
        itemClass            : PlanProductListItemView

    @listView = @quantititesList.getView()

    @plan.fetchProducts (err,products)=>
      return new KDNotificationView title : err if err
      for product in products
        quantity = @plan.quantities[product.planCode]
        @quantititesList.addItem {product,quantity}

  pistachio:->
    total = KD.utils.formatMoney @plan.feeAmount / 100
    """
      #{@plan.title}
      Total Amount : #{total}
    """

class PlanProductListItemView extends KDListItemView
  constructor:(options = {}, data)->
    options.tagName = 'span'
    super options, data

    {@title} = @getData().product
    {@quantity} = @getData()

  viewAppended: JView::viewAppended

  pistachio:->
    """
    #{@title} - #{@quantity}
    """
