class ResourcesContainer extends KDView
  constructor: (options = {}, data) ->
    options.tagName  = 'section'
    options.cssClass = KD.utils.curry 'resources-container', options.cssClass
    super options, data

  addSubscriptions: ->
    tag = if KD.getGroup().slug is "koding" then "vm" else "custom-plan"
    payment = KD.singleton "paymentController"
    payment.fetchSubscriptionsWithPlans tags: [tag], (err, [subscription]) =>
      return new KDNotificationView title: err  if err
      @subscriptions.addSubView new SubscriptionUsageView null, subscription  if subscription

  viewAppended: ->
    @addSubView @titleBar = new KDCustomHTMLView
      tagName  : 'header'
      partial  : '<h3>Resource Packs</h3><h4>Need some more power</h4>'

    @titleBar.addSubView new KDButtonView
      cssClass : 'solid green small'
      title    : 'UPGRADE'
      callback : (event)->
        KD.utils.stopDOMEvent event
        KD.singleton('router').handleRoute '/Pricing/Developer'

    @addSubView @subscriptions = new KDCustomHTMLView tagName: 'section'

    @addSubscriptions()
