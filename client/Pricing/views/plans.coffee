class PricingPlansView extends KDView

  initialState:
    currentPlan: null

  constructor: (options = {}, data) ->

    options.tagName  = "section"
    options.cssClass = "plans clearfix"

    super options, data

    { state } = options

    @state = @utils.extend @initialState, state

    @planViews = {}


  viewAppended: ->

    for plan in @plans
      plan.delegate = this
      planTitle = plan.title.toLowerCase()
      isCurrentPlan = @state.currentPlan is planTitle
      plan.cssClass = @utils.curry 'current'  if isCurrentPlan
      @addSubView view = new SinglePlanView plan
      @forwardEvent view, "PlanSelected"
      view.disable()  if isCurrentPlan

      @planViews[planTitle] = view


  plans: [
    title        : 'Free'
    monthPrice   : 0
    yearPrice    : 0
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
    monthPrice   : 900
    yearPrice    : 9720
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
    monthPrice   : 1900
    yearPrice    : 20520
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
    monthPrice   : 3900
    yearPrice    : 42120
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

