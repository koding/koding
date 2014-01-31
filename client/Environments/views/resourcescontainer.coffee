class ResourcesContainer extends KDView

  constructor:(options = {}, data)->

    options.tagName  = 'section'
    options.cssClass = 'resources-container'

    super options, data


  fetchSubscriptions:->

    KD.whoami().fetchSubscriptions
      tags : ['vm','custom-plan']
    , (err, subscriptions)=>
      if err
        return new KDNotificationView title : err

      subscriptions.forEach @bound 'fetchProducts'


  fetchProducts:(subscription)->

    KD.remote.api.JPaymentProduct.some
      planCode : $in : Object.keys subscription.quantities
    ,
      limit: 20
    , (err, products)=>
      if err
        return new KDNotificationView title : err

      @subscriptions.addSubView new SubscriptionUsageView
        subscription : subscription
        components   : products


  viewAppended:->

    @addSubView @titleBar = new KDCustomHTMLView
      tagName  : 'header'
      partial  : '<h3>Resource Packs</h3><h4>Need some more power</h4>'

    @titleBar.addSubView new KDButtonView
      cssClass : 'solid green small'
      title    : 'UPGRADE'
      callback : (event)->
        KD.utils.stopDOMEvent event
        KD.singleton('router').handleRoute '/Pricing/Developer'

    @addSubView @subscriptions = new KDCustomHTMLView
      tagName  : 'section'

    @fetchSubscriptions()
