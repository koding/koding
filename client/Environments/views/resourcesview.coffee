class ResourcesView extends KDView

  constructor:(options = {}, data)->

    options.cssClass = 'gauges'

    super options, data

    @fetchProducts (err, products)=>
      if err
        return new KDNotificationView title : err

      @addSubView new SubscriptionUsageView
        subscription : @getData()
        components   : products


  fetchProducts:(callback)->

    KD.remote.api.JPaymentProduct.some
      planCode : $in : Object.keys @getData().quantities
    ,
      limit: 20
    , callback
