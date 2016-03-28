kd                  = require 'kd'
HomeTeamBillingForm = require './hometeambillingform'

module.exports = class HomeTeamBilling extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    @wrapper.addSubView new HomeTeamBillingForm