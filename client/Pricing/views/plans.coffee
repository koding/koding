class PricingPlansView extends KDView

  constructor: (options = {}, data) ->

    options.tagName  = "section"
    options.cssClass = "plans clearfix"

    super options, data

    @planViews = {}


  viewAppended: ->

    for plan in @plans
      plan.delegate = this
      @addSubView view = new SinglePlanView plan
      @forwardEvent view, "PlanSelected"

      @planViews[plan.title.toLowerCase()] = view


  plans: [
    title        : 'Free'
    price        : 0
    description  : 'Great for sad pandas and SEO engineers'
    cssClass     : 'free'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '1 Core'       , cssClass: 'cpu' }
      { partial: '3 GB Storage' , cssClass: 'storage' }
      { partial: '3 VMs'        , cssClass: 'vm-count' }
      { partial: 'Always on'    , cssClass: 'always-on disabled' }
    ]
  ,
    title        : 'Hobbyist'
    price        : 900
    description  : 'Great for single women and ice create lovin protoganists'
    cssClass     : 'hobbyist'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '1 Core'       , cssClass: 'cpu' }
      { partial: '3 GB Storage' , cssClass: 'storage' }
      { partial: '3 VMs'        , cssClass: 'vm-count' }
      { partial: 'Always on'    , cssClass: 'always-on disabled' }
    ]
  ,
    title        : 'Developer'
    price        : 1900
    description  : 'Great for sad pandas and SEO engineers'
    cssClass     : 'developer current'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '1 Core'       , cssClass: 'cpu' }
      { partial: '15 GB Storage', cssClass: 'storage' }
      { partial: '3 VMs'        , cssClass: 'vm-count' }
      { partial: '1 Always on'  , cssClass: 'always-on' }
    ]
  ,
    title        : 'Professional'
    price        : 3900
    description  : 'Great for Data Analysis, wordpress installs'
    cssClass     : 'professional'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '5 Core'       , cssClass: 'cpu' }
      { partial: '25 GB Storage', cssClass: 'storage' }
      { partial: '5 VMs'        , cssClass: 'vm-count' }
      { partial: '2 Always on'  , cssClass: 'always-on' }
    ]
  ]

