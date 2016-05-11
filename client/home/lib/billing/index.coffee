kd                                = require 'kd'
HomeTeamBillingPaymentInformation = require './hometeambillingpaymentinformation'
HomeTeamBillingCreditCard         = require './hometeambillingcreditcard'
HomeTeamBillingPlansList = require './hometeambillingplanslist'

PaymentFlux = require 'app/flux/payment'

SECTIONS =
  'Koding Subscription': HomeTeamBillingPlansList
  'Payment Information': HomeTeamBillingPaymentInformation
  'Credit Card': HomeTeamBillingCreditCard


header = (title) ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'
    partial  : title


section = (name) -> new SECTIONS[name]


module.exports = class HomeTeamBilling extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    { mainController, reactor } = kd.singletons

    mainController.ready =>
      PaymentFlux(reactor).actions.loadGroupCreditCard()

      @wrapper.addSubView header 'Koding Subscription'
      @wrapper.addSubView section 'Koding Subscription'

      formView = new kd.FormView
        cssClass: kd.utils.curry 'HomeAppView--billing-form', options.cssClass

      formView.addSubView header 'Payment Information'
      formView.addSubView section 'Credit Card'
      formView.addSubView section 'Payment Information'

      @wrapper.addSubView formView

