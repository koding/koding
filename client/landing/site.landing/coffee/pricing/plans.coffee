SinglePlanView = require './singleplan'

module.exports = class PricingPlansView extends KDView

  getInitialState: -> KD.utils.dict()

  constructor: (options = {}, data) ->

    options.tagName  = 'section'
    options.cssClass = 'plans clearfix'

    super options, data

    @state = KD.utils.extend @getInitialState(), options.state

    @planViews = {}

    @initViews()

  initViews: ->

    for plan in @plans
      plan.delegate = this
      planTitle = plan.title.toLowerCase()
      plan.state = @state
      @addSubView view = new SinglePlanView plan
      @forwardEvent view, 'PlanSelected'
      @planViews[planTitle] = view


  switchTo: (planInterval) ->

    plan.setPlanInterval(planInterval)  for _, plan of @planViews


  plans: [
    title        : 'Free'
    monthPrice   : '0'
    reducedMonth : '0'
    yearPrice    : '0'
    discount     : '0'
    description  : 'Best for tinkering with and learning new technologies'
    cssClass     : 'free'
    planFeatures : [
      { partial: '1 VM'           , cssClass: 'vm-count' }
      { partial: '1 Core'         , cssClass: 'cpu' }
      { partial: '1GB RAM'        , cssClass: 'ram' }
      { partial: '3GB Total Disk' , cssClass: 'storage' }
      { partial: '0 Always on VM' , cssClass: 'always-on disabled' }
    ]
  ,
    title        : 'Hobbyist'
    monthPrice   : '12.50'
    reducedMonth : '9.95'
    yearPrice    : '119.40'
    discount     : 255
    description  : 'Best for expanded learning or for running a small blog/website'
    cssClass     : 'hobbyist'
    planFeatures : [
      { partial: '1 VM '          , cssClass: 'vm-count' }
      { partial: '1 Core'         , cssClass: 'cpu' }
      { partial: '1GB RAM'        , cssClass: 'ram' }
      { partial: '10GB Storage'   , cssClass: 'storage' }
      { partial: '1 Always on VM' , cssClass: 'always-on disabled' }
    ]
  ,
    title        : 'Developer'
    monthPrice   : '24.50'
    reducedMonth : '19.95'
    yearPrice    : '239.40'
    discount     : 455
    description  : 'Great for developers who work with multiple environments'
    cssClass     : 'developer'
    planFeatures : [
      { partial: '3 VMs '          , cssClass: 'vm-count' }
      { partial: '1 Core each'     , cssClass: 'cpu' }
      { partial: '1GB RAM each'    , cssClass: 'ram' }
      { partial: '25GB Total Disk' , cssClass: 'storage' }
      { partial: '1 Always on VM'  , cssClass: 'always-on' }
    ]
  ,
    title        : 'Professional'
    monthPrice   : '49.50'
    reducedMonth : '39.95'
    yearPrice    : '479.40'
    discount     : 955
    description  : 'Great for managing and delivering client work'
    cssClass     : 'professional'
    planFeatures : [
      { partial: '5 VMs '          , cssClass: 'vm-count' }
      { partial: '1 Core each'     , cssClass: 'cpu' }
      { partial: '1GB RAM each'    , cssClass: 'ram' }
      { partial: '50GB Total Disk' , cssClass: 'storage' }
      { partial: '2 Always on VMs' , cssClass: 'always-on' }
    ]
  ]


