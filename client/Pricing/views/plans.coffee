class PricingPlansView extends KDView

  constructor: (options = {}, data) ->

    options.tagName  = "section"
    options.cssClass = "plans clearfix"

    super options, data

    @state = {}

    @planViews = {}

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
    description  : 'Best for tinkering with and learning new technologies'
    cssClass     : 'free'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '1 Core'       , cssClass: 'cpu' }
      { partial: '3 GB Storage' , cssClass: 'storage' }
      { partial: '1 VM total'   , cssClass: 'vm-count' }
      { partial: '0 Always on'  , cssClass: 'always-on disabled' }
    ]
  ,
    title        : 'Hobbyist'
    monthPrice   : 995
    reducedMonth : 896
    yearPrice    : 10789
    discount     : 100
    description  : 'Best for expanded learning or for running a small blog/website'
    cssClass     : 'hobbyist'
    planFeatures : [
      { partial: '1 GB RAM'     , cssClass: 'ram' }
      { partial: '1 Core'       , cssClass: 'cpu' }
      { partial: '3 GB Storage' , cssClass: 'storage' }
      { partial: '1 VM total'   , cssClass: 'vm-count' }
      { partial: '1 Always on'  , cssClass: 'always-on disabled' }
    ]
  ,
    title        : 'Developer'
    monthPrice   : 1995
    reducedMonth : 1796
    yearPrice    : 21589
    discount     : 200
    description  : 'Great for developers who work with multiple environments'
    cssClass     : 'developer'
    planFeatures : [
      { partial: '1 GB RAM'      , cssClass: 'ram' }
      { partial: '1 Core'        , cssClass: 'cpu' }
      { partial: '15 GB Storage' , cssClass: 'storage' }
      { partial: '3 VMs total'   , cssClass: 'vm-count' }
      { partial: '1 Always on'   , cssClass: 'always-on' }
    ]
  ,
    title        : 'Professional'
    monthPrice   : 4995
    reducedMonth : 4496
    yearPrice    : 53989
    discount     : 500
    description  : 'Great for managing and delivering client work'
    cssClass     : 'professional'
    planFeatures : [
      { partial: '1 GB RAM'      , cssClass: 'ram' }
      { partial: '1 Core'        , cssClass: 'cpu' }
      { partial: '25 GB Storage' , cssClass: 'storage' }
      { partial: '5 VMs total'   , cssClass: 'vm-count' }
      { partial: '2 Always on'   , cssClass: 'always-on' }
    ]
  ]

