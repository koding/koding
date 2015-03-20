kd = require 'kd'
KDView = kd.View
SinglePlanView = require './singleplanview'


module.exports = class PricingPlansView extends KDView

  getInitialState: -> kd.utils.dict()

  constructor: (options = {}, data) ->

    options.tagName  = 'section'
    options.cssClass = 'plans clearfix'

    super options, data

    @state = kd.utils.extend @getInitialState(), options.state

    @planViews = {}

    for plan in @plans
      plan.delegate = this
      planTitle = plan.title.toLowerCase()
      plan.state = @state
      @addSubView view = new SinglePlanView plan
      @forwardEvent view, 'PlanSelected'
      @planViews[planTitle] = view


  switchTo: (planInterval) ->

    plan.setPlanInterval(planInterval)  for _, plan of @planViews
    @state.planInterval = planInterval
    @refresh()


  setState: (state) ->

    kd.utils.extend @state, state

    @refresh()


  setPromotedPlan: (promotedPlan) ->

    for title, planView of @planViews

      planView.enable()

      if title is promotedPlan
      then planView.setClass 'promoted'
      else planView.unsetClass 'promoted'


  refresh: ->

    { planInterval, currentPlanInterval, subscriptionState
      planTitle, currentPlan, promotedPlan } = @state

    isSameInterval    = planInterval is currentPlanInterval
    isCurrentPlanFree = currentPlan is 'free'
    isExpired         = subscriptionState is 'expired'

    if isExpired
      lowerPlans = getLowerPlans currentPlan
      # disable plan without setting css class to 'current'
      # the argument 'no' implies that.
      @planViews[title].disable no  for title in lowerPlans

    else if isCurrentPlanFree
      @setPromotedPlan promotedPlan
      @planViews['free'].disable()

    else if isSameInterval
      @setPromotedPlan null
      @planViews[currentPlan].disable()

    else
      @setPromotedPlan promotedPlan


  ###*
   * It gets the name of the plan
   * and returns an array that has the names
   * of lower plans.
  ###
  getLowerPlans = (planTitle) ->

    plans = ['free', 'hobbyist', 'developer', 'professional']

    index = plans.indexOf planTitle

    return plans.slice 0, index


  plans: [
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
      { partial: '10GB Total Disk', cssClass: 'storage' }
      { partial: '1 Always on VM' , cssClass: 'always-on disabled' }
    ]
  ,
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
  ]
