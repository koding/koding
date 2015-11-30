kd                = require 'kd'
KDView            = kd.View
KDButtonGroupView = kd.ButtonGroupView
KDCustomHTMLView  = kd.CustomHTMLView
PricingPlansView  = require './views/pricingplansview'
isLoggedIn        = require 'app/util/isLoggedIn'
showError         = require 'app/util/showError'
PaymentWorkflow   = require 'app/payment/paymentworkflow'
PaymentConstants  = require 'app/payment/paymentconstants'
JView             = require 'app/jview'
FooterView        = require 'app/commonviews/footerview'
CustomLinkView    = require 'app/customlinkview'
globals           = require 'globals'


module.exports = class PricingAppView extends KDView


  { KEY, DURATION } = PaymentConstants.FAILED_ATTEMPTS.PRICING


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

    options.cssClass = kd.utils.curry "content-page pricing", options.cssClass

    super options, data

    @state = kd.utils.extend @getInitialState(), options.state

    # it's going to be assigned by 'PricingAppController'.
    @appStorage = null

    @loadPlan()  if isLoggedIn()
    @initViews()
    @initEvents()

    { planInterval, promotedPlan } = @state

    @plans.planViews[promotedPlan].setClass 'promoted'  unless isLoggedIn()
    @selectIntervalToggle @state.planInterval


  initViews: ->

    @header = new KDCustomHTMLView
      partial   : "Our pricing, your terms"
      tagName   : "h4"
      cssClass  : "pricing-heading"

    @headerDescription = new KDCustomHTMLView
      tagName   : 'p'
      cssClass  : 'pricing-description'
      partial   : "
        Get started for free or go right into high gear with one of our paid plans.
        Our simple pricing is designed to help you get the most out of your Koding experience.
        Trusted by your peers worldwide.
      "

    @intervalToggle = new KDButtonGroupView
      cssClass     : 'interval-toggle'
      buttons      :
        'month'    :
          title    : 'MONTHLY'
          callback : => @emit 'IntervalToggleChanged', { planInterval : 'month' }
        'year'     :
          title    : 'YEARLY'
          callback : => @emit 'IntervalToggleChanged', { planInterval : 'year' }

    @plans = new PricingPlansView { @state }

    @footer = @initFooter()

    @kodingFooter = new FooterView


  initEvents: ->

    @plans.on 'PlanSelected', @bound 'planSelected'

    @on 'IntervalToggleChanged', @bound 'handleToggleChanged'


  initFooter: ->

    features = [
      'Full sudo access'
      'VMs hosted on Amazon EC2'
      'SSH Access'
      'Unlimited workspaces'

      'Custom sub-domains'
      'Publicly accessible IP'
      'Ubuntu 14.04'
      'Built-in IDE and Terminal'

      'Realtime collaboration'
      'Audio/Video in collaboration'
      'Custom IDE shortcuts'
      'Connect your own VM'
    ]

    footer = new KDCustomHTMLView
      cssClass : 'pricing-footer'

    footer.addSubView new KDCustomHTMLView
      tagName : 'h4'
      partial : 'All plans include:'

    footer.addSubView featuresWrapper = new KDCustomHTMLView
      tagName  : 'ul'
      cssClass : 'features clearfix'

    features.forEach (feature) ->
      featuresWrapper.addSubView new KDCustomHTMLView
        tagName  : 'li'
        cssClass : 'single-feature'
        partial  : feature

    footer.addSubView new CustomLinkView
      title    : 'Learn more about all our features'
      cssClass : "learn-more"
      href     : "/Features"

    footer.addSubView new KDCustomHTMLView
      cssClass : 'footer-msg'
      partial  : "
        <p>Don't worry, you can upgrade or downgrade your plan at any time.</p>
        <p class='footer-note'>(you can cancel a yearly plan within 3 months -
        no questions asked! outside of 3 months there is 2 month fee.)</p>
      "

    return footer


  selectIntervalToggle: (planInterval) ->

    button = @intervalToggle.buttons[planInterval]
    @intervalToggle.buttonReceivedClick button


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

      @appStorage.fetchValue KEY, (result) =>

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

    kd.utils.defer => @appStorage.unsetKey KEY


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
        @state.inProcess = no
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
      {{> @header}}
      {{> @headerDescription}}
      {{> @intervalToggle}}
      {{> @plans}}
      {{> @footer}}
      {{> @kodingFooter}}
    """
