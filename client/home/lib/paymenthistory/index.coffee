kd = require 'kd'
HomeTeamInvoicesList = require './hometeaminvoiceslist'
{ load: loadInvoices } = require 'app/redux/modules/payment/invoices'

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

    { mainController, store } = kd.singletons

    mainController.ready =>
      store.dispatch(loadInvoices())

      @wrapper.addSubView header = header()

      header.addSubView new kd.CustomHTMLView
        tagName : 'a'
        partial : 'BACK TO TEAM BILLING'
        click : ->
          kd.singletons.router.handleRoute '/Home/team-billing'

      @wrapper.addSubView section 'Payment History'
