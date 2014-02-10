class PlanProductListView extends KDView
  constructor: (options = {}, data) ->
    super options, data

    data.fetchProducts (err, products) =>
      return new KDNotificationView title: err  if err
      for product in products
        quantity = data.quantities[product.planCode]
        @addSubView new KDCustomHTMLView partial: "#{quantity}x #{product.title}"
