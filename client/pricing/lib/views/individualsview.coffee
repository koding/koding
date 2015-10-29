kd                  = require 'kd'
JView               = require 'app/jview'
KDView              = kd.View
KDTabView           = kd.TabView
KDSelectBox         = kd.SelectBox
KDTabPaneView       = kd.TabPaneView
KDCustomHTMLView    = kd.CustomHTMLView

isLoggedIn          = require 'app/util/isLoggedIn'
showError           = require 'app/util/showError'
PricingPlansView    = require './pricingplansview'
PaymentWorkflow     = require 'app/payment/paymentworkflow'
PaymentConstants    = require 'app/payment/paymentconstants'


{ KEY, DURATION }   = PaymentConstants.FAILED_ATTEMPTS.PRICING


module.exports = class IndividualsView extends KDView

  JView.mixin @prototype

  getInitialState : ->

    dayOfWeek = (new Date).getDay()
    reversePlans = dayOfWeek in [2, 4, 6, 7]

    return {
      inProcess : no
      planInterval : 'year'
      promotedPlan : if reversePlans then 'developer' else 'hobbyist'
      reversePlans
    }


  constructor: (options = {}, data) ->

    super options, data

    @state = kd.utils.extend @getInitialState(), options.state

    @loadPlan()
    @initViews()
    @initEvents()

    { planInterval, promotedPlan } = @state

    @plans.planViews[promotedPlan].setClass 'promoted'
    @selectIntervalToggle @state.planInterval


  initViews: ->

    @intervalToggleView = new KDCustomHTMLView
      cssClass        : 'interval-toggle'

    @intervalToggleView.addSubView new KDCustomHTMLView
      partial         : "I'd like to be billed"
      tagName         : 'span'

    @intervalToggleView.addSubView @intervalToggle = new KDSelectBox
      defaultValue    : 'month'
      selectOptions   : [
        { title : 'by month', value : 'month' }
        { title : 'by year',  value : 'year' }
      ]
      callback        : (value) =>
        @emit 'IntervalToggleChanged', { planInterval : value }

    @plans = new PricingPlansView { @state }

    @noWorries = new KDCustomHTMLView
      cssClass        : 'no-worries'
      partial         : """
        Can't decide on a plan?<br/>
        No worries, you can upgrade or downgrade anytime.
      """


  initEvents: ->

    @plans.on 'PlanSelected',     @bound 'planSelected'
    @on 'IntervalToggleChanged',  @bound 'handleToggleChanged'


  selectIntervalToggle: (planInterval) ->

    @intervalToggle.setValue planInterval


  handleToggleChanged: ({ planInterval }) ->

    @state.planInterval = planInterval

    @selectIntervalToggle planInterval

    @plans.switchTo planInterval


  loadPlan: (callback = kd.noop) ->

    { paymentController } = kd.singletons

    paymentController.subscriptions (err, subscription) =>

      return showError err  if err?

      { planTitle, provider, planInterval, state } = subscription

      @state.provider            = provider
      @state.currentPlan         = planTitle
      @state.subscriptionState   = state
      @state.currentPlanInterval = planInterval
      @state.planInterval        = if planTitle is 'free' then 'year' else planInterval

      @plans.setState @state

      @handleToggleChanged planInterval: @state.planInterval

      callback()


  preventBlockedUser: (options, callback) ->

    kd.utils.defer =>

      @getDelegate().appStorage.fetchValue KEY, (result) =>

        return callback()  unless result

        difference = Date.now() - result.timestamp

        if difference < DURATION

          @workflowController = new PaymentWorkflow { state: options, delegate: this }

          @workflowController.on PaymentConstants.events.WORKFLOW_STARTED, =>
            @state.inProcess = no
            @workflowController.failedAttemptLimitReached no

          workflowCouldNotStart = PaymentConstants.events.WORKFLOW_COULD_NOT_START

          @workflowController.on workflowCouldNotStart, =>
            @emit PaymentConstants.events.WORKFLOW_COULD_NOT_START
            @state.inProcess = no

          return

        @removeBlockFromUser()

        return callback()


  removeBlockFromUser: ->

    kd.utils.defer => @getDelegate().appStorage.unsetKey KEY


  ###*
   * This method uses `preventBlockedUser` method as a
   * before filter, that filter will decide
   * if this method will be called or not.
  ###
  planSelected: (options) ->

    return  if @state.inProcess

    @state.inProcess = yes

    @preventBlockedUser options, =>

      return kd.singletons
        .router
        .handleRoute '/Login'  unless isLoggedIn()

      { currentPlan, currentPlanInterval,
        subscriptionState, provider, inProcess } = @state

      # wait for loading the current plan,
      # call this method until it's ready.
      unless currentPlan?
        return @loadPlan => @planSelected options

      isCurrentPlan =
        options.planTitle     is currentPlan and
        (options.planInterval is currentPlanInterval or
        options.planTitle     is PaymentConstants.planTitle.FREE) and
        'expired'             isnt subscriptionState

      if isCurrentPlan
        inProcess = no
        return showError "That's already your current plan."

      { PAYPAL, KODING } = PaymentConstants.provider

      # change the provider to koding to make other views work.
      if provider is PAYPAL
        if subscriptionState is 'expired'
          options.provider = KODING

      @setState options

      @workflowController = new PaymentWorkflow { @state, delegate: this }

      @workflowController.on PaymentConstants.events.WORKFLOW_STARTED, (state) =>
        @emit PaymentConstants.events.WORKFLOW_STARTED
        @state.inProcess = no

      @workflowController.on PaymentConstants.events.WORKFLOW_COULD_NOT_START, =>
        @emit PaymentConstants.events.WORKFLOW_COULD_NOT_START
        @state.inProcess = no

      @workflowController.once 'PaymentWorkflowFinishedSuccessfully', (state) =>

        @state.currentPlan = state.planTitle
        @state.currentPlanInterval = state.planInterval
        @state.provider = state.provider
        @plans.setState @state

        kd.singletons.router.handleRoute '/'
        kd.utils.defer ->
          kd.singletons.paymentController.emit 'PaymentWorkflowFinishedSuccessfully'


  continueFrom: (planTitle, planInterval) ->

    @emit 'IntervalToggleChanged', {planInterval}

    plan = @plans.planViews[planTitle]
    plan.select()


  setState: (obj) -> @state = kd.utils.extend @state, obj


  pistachio: ->
    """
      {{> @intervalToggleView}}
      {{> @plans}}
      {{> @noWorries}}
    """
