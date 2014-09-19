class PricingPlansView extends KDView

  constructor: (options = {}, data) ->

    options.tagName  = "section"
    options.cssClass = "plans clearfix"

    super options, data

    @state = {}

    @planViews = {}


  viewAppended: ->

    for plan in @plans
      plan.delegate = this
      planTitle = plan.title.toLowerCase()
      @addSubView view = new SinglePlanView plan
      @forwardEvent view, "PlanSelected"
      @planViews[planTitle] = view


  plans: [
    title        : 'Free'
    monthPrice   : 0
    reducedMonth : 0
    yearPrice    : 0
    discount     : 0
    description  : 'Great for sad pandas and SEO engineers'
    cssClass     : 'free'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '1 Core'       , cssClass: 'cpu' }
      { partial: '3 GB Storage' , cssClass: 'storage' }
      { partial: '3 VMs'        , cssClass: 'vm-count' }
      { partial: '0 Always on'  , cssClass: 'always-on disabled' }
    ]
  ,
    title        : 'Hobbyist'
    monthPrice   : 999
    reducedMonth : 899
    yearPrice    : 10789
    discount     : 100
    description  : 'Great for single women and ice create lovin protoganists'
    cssClass     : 'hobbyist'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '1 Core'       , cssClass: 'cpu' }
      { partial: '3 GB Storage' , cssClass: 'storage' }
      { partial: '3 VMs'        , cssClass: 'vm-count' }
      { partial: '1 Always on'  , cssClass: 'always-on disabled' }
    ]
  ,
    title        : 'Developer'
    monthPrice   : 1999
    reducedMonth : 1799
    yearPrice    : 21589
    discount     : 200
    description  : 'Great for sad pandas and SEO engineers'
    cssClass     : 'developer'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '1 Core'       , cssClass: 'cpu' }
      { partial: '15 GB Storage', cssClass: 'storage' }
      { partial: '3 VMs'        , cssClass: 'vm-count' }
      { partial: '1 Always on'  , cssClass: 'always-on' }
    ]
  ,
    title        : 'Professional'
    monthPrice   : 4999
    reducedMonth : 4499
    yearPrice    : 53989
    discount     : 500
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

