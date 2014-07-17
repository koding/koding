class PricingProductForm extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "product-form", options.cssClass
    super options, data

    @developerPlan = new DeveloperPlan
    @developerPlan.on "PlanSelected", @bound "selectPlan"

    @teamPlan = new TeamPlan
    @teamPlan.on "PlanSelected", @bound "selectPlan"

    @tabView = new KDTabView
      cssClass            : "pricing-type-tab"
      hideHandleContainer : yes

    @tabView.addPane @developerPane = new KDTabPaneView
      name: 'Developer'
      view: @developerPlan

    @tabView.addPane @teamPane = new KDTabPaneView
      name: 'Team'
      view: @teamPlan

    @teamPlan.once 'viewAppended', =>
      KD.utils.defer =>
        @teamPlan.addSubView new PricingCustomQuoteView {cssClass : 'clearfix'}

  showSection: (name) ->
    @tabView.showPaneByName name

  selectPlan: (tag, groupTag, options) ->
    paymentController = KD.singleton "paymentController"
    paymentController.fetchSubscriptionsWithPlans tags: [tag], (err, subscriptions) =>
      return KD.showError "You are already subscribed to this plan"  if subscriptions.length
      KD.remote.api.JPaymentPlan.one tags: $in: [tag], (err, plan) =>
        return  if KD.showError err
        @emit "PlanSelected", plan, options

    if KD.isLoggedIn()
      @setExistingSubscription groupTag
    else
      mainController = KD.singleton "mainController"
      mainController.once "accountChanged.to.loggedIn", @lazyBound "setExistingSubscription", groupTag

  setExistingSubscription: (tag) ->
    paymentController = KD.singleton "paymentController"
    paymentController.fetchActiveSubscription [tag], (err, subscription) =>
      return KD.showError err  if err and err.code isnt "no subscription"
      @emit "CurrentSubscriptionSet", subscription  if subscription

  viewAppended: ->
    @addSubView new PricingIntroductionView
    @addSubView @tabView
    @addSubView new PricingFeaturesView
    @addSubView new FooterView
