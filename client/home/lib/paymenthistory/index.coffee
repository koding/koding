kd = require 'kd'
HomeTeamInvoicesList = require './hometeaminvoiceslist'
PaymentFlux = require 'app/flux/payment'

SECTIONS =
  'Payment History': HomeTeamInvoicesList

header = ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'

section = (name) -> new SECTIONS[name]

module.exports = class HomePaymentHistory extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    { mainController, reactor } = kd.singletons

    mainController.ready =>
      PaymentFlux(reactor).actions.loadGroupInvoices()

      @wrapper.addSubView header = header()

      header.addSubView new kd.CustomHTMLView
        tagName : 'a'
        partial : 'BACK TO TEAM BILLING'
        click : ->
          kd.singletons.router.handleRoute '/Home/team-billing'

      @wrapper.addSubView section 'Payment History'
