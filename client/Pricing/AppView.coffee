class PricingAppView extends KDView

  JView.mixin @prototype

  constructor:(options = {}, data) ->

    options.cssClass = KD.utils.curry "content-page pricing", options.cssClass

    super options, data


    @state = {}

    @loadPlan()  if KD.isLoggedIn()
    @initViews()
    @initEvents()

    @plans.planViews['hobbyist'].setClass 'promoted'  unless KD.isLoggedIn()


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

    @plans = new PricingPlansView { @state }

    @info = new KDCustomHTMLView
      tagName   : 'p'
      cssClass  : 'pricing-footer'
      partial   : "
        All plans include: <span>Non-hypervised VMs, full sudo access, custom sub-domains, SSL and SSH access</span>
      "

    @learnMoreLink = new CustomLinkView
      title    : "Learn more about all our features"
      cssClass : "learn-more"
      href     : "/"


  initEvents: ->
    @plans.on 'PlanSelected', @bound 'planSelected'


  loadPlan: (callback = noop) ->

    { paymentController } = KD.singletons

    paymentController.subscriptions (err, subscription) =>
      { planTitle } = subscription

      @state.currentPlan = planTitle
      @plans.planViews[planTitle].disable()

      @plans.planViews['hobbyist'].setClass 'promoted'  if planTitle is 'free'

      callback()


  planSelected: (options) ->

    return window.location.replace '/Register'  unless KD.isLoggedIn()
    return @loadPlan @bound 'planSelected'      unless @state.currentPlan?

    {
      planTitle, monthPrice, yearPrice, reducedMonth, discount
    } = options

    @workflowController = new PaymentWorkflow {
      @state, planTitle, monthPrice, yearPrice
      reducedMonth, discount, view: this
    }

    @workflowController.on 'PaymentWorkflowFinishedSuccessfully', (state) =>

      oldPlanTitle = @state.currentPlan
      @plans.planViews[oldPlanTitle].enable()

      { planTitle } = state
      @plans.planViews[planTitle].disable()

      @state.currentPlan = state.planTitle

      { router } = KD.singletons

      KD.utils.wait 500, -> router.handleRoute '/'


  pistachio: ->
    """
      {{> @header}}
      {{> @headerDescription}}
      {{> @plans}}
      {{> @info}}
      {{> @learnMoreLink}}
    """


