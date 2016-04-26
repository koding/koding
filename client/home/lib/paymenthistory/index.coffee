kd = require 'kd'
HomeTeamInvoicesList = require './hometeaminvoiceslist'
PaymentFlux = require 'app/flux/payment'

SECTIONS =
  'Payment History': HomeTeamInvoicesList

header = (title) ->
  new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'
    partial  : title

section = (name) -> new SECTIONS[name]

module.exports = class HomePaymentHistory extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    { mainController, reactor } = kd.singletons

    mainController.ready =>
      PaymentFlux(reactor).actions.loadGroupInvoices()

      @wrapper.addSubView header 'Payment History'
      @wrapper.addSubView section 'Payment History'


