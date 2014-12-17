class PricingAppView extends KDView

  JView.mixin @prototype

  getInitialState : ->
    {
      planInterval : 'year'
      promotedPlan : 'hobbyist'
    }

  constructor:(options = {}, data) ->

    options.cssClass = KD.utils.curry "content-page pricing", options.cssClass

    super options, data

    @state = KD.utils.extend @getInitialState(), options.state

    @loadPlan()  if KD.isLoggedIn()
    @initViews()
    @initEvents()

    { planInterval, promotedPlan } = @state

    @plans.planViews[promotedPlan].setClass 'promoted'  unless KD.isLoggedIn()
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
      'Real EC2 VM, no LXCs/hypervising'

      'Custom sub-domains'
      'Publicly accessible IP'
      'Ubuntu 14.04'
      'IDE/Terminal/Collaboration'
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


  loadPlan: (callback = noop) ->

    { paymentController } = KD.singletons

    paymentController.subscriptions (err, subscription) =>

      return KD.showError err  if err?

      { planTitle, provider, planInterval } = subscription

      @state.currentPlan         = planTitle
      @state.provider            = provider
      @state.currentPlanInterval = planInterval

      @plans.setState @state

      callback()


  planSelected: (options) ->

    return KD.singletons
      .router
      .handleRoute '/Login'  unless KD.isLoggedIn()

    return @loadPlan @lazyBound 'planSelected', options  unless @state.currentPlan?

    isCurrentPlan =
      options.planTitle    is @state.currentPlan and
      options.planInterval is @state.currentPlanInterval

    return KD.showError "That's already your current plan."  if isCurrentPlan

    @setState options

    @workflowController = new PaymentWorkflow { @state, delegate: this }

    @workflowController.once 'PaymentWorkflowFinishedSuccessfully', (state) =>

      @state.currentPlan = state.planTitle
      @plans.setState @state

      KD.singletons
        .router
        .handleRoute '/'


  continueFrom: (planTitle, planInterval) ->

    @emit 'IntervalToggleChanged', {planInterval}

    plan = @plans.planViews[planTitle]
    plan.select()


  setState: (obj) -> @state = KD.utils.extend @state, obj


  pistachio: ->
    """
      {{> @header}}
      {{> @headerDescription}}
      {{> @intervalToggle}}
      {{> @plans}}
      {{> @footer}}
      {{> @kodingFooter}}
    """


