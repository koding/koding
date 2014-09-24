class PricingProductForm extends KDView
  constructor: (options = {}, data) ->
    KodingAppsController.appendHeadElements
      identifier : "stripe"
      items      : [
        {
          type   : 'script'
          url    : "https://js.stripe.com/v2/"
        }
      ]

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

  selectPlan: (tag, groupTag, options, planName, price)->
    log ">>>>>>>>> selectPlan", arguments...

    Stripe.setPublishableKey 'pk_test_Gw43pxyKHJl2XZWA4q8ZvoAv'

    paymentModal = new NewPaymentModal {planName, price}
    paymentModal.on "PaymentSubmitted", (formData)->
      {cardNumber, cardCVC, cardNumber, cardMonth, cardYear} = formData

      console.log ">>>>>>>> PaymentSubmitted", formData

      Stripe.card.createToken
        number    : cardNumber
        cvc       : cardCVC
        exp_month : cardMonth
        exp_year  : cardYear
      , (status, response)->
        return console.log "ERROR: ", response  if response.error

        console.log response

  setExistingSubscription: (tag) ->
    paymentController = KD.singleton "paymentController"
    paymentController.fetchActiveSubscription [tag], (err, subscription) =>
      return KD.showError err  if err and err.code isnt "no subscription"
      @emit "CurrentSubscriptionSet", subscription  if subscription

  viewAppended: ->
    @addSubView @tabView
    @addSubView new FooterView
