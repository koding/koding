kd = require 'kd'
headerize = require '../commons/headerize'
sectionize = require '../commons/sectionize'
isFeatureEnabled = require 'app/util/isFeatureEnabled'

HomeAccountEditProfile = require './homeaccounteditprofile'
HomeAccountChangePassword = require './homeaccountchangepassword'
HomeAccountSecurityView = require './homeaccountsecurityview'
HomeAccountIntegrationsView = require './homeaccountintegrationsview'
HomeAccountSessionsView = require './homeaccountsessionsview'


module.exports = class HomeAccount extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    @wrapper.addSubView headerize 'My Account'
    @wrapper.addSubView sectionize 'Profile', HomeAccountEditProfile

    @wrapper.addSubView headerize 'Password'
    @wrapper.addSubView sectionize 'Password', HomeAccountChangePassword

    @wrapper.addSubView headerize 'Security'
    @wrapper.addSubView sectionize 'Security', HomeAccountSecurityView

    if isFeatureEnabled 'gitlab'
      @wrapper.addSubView headerize 'Integrations'
      @wrapper.addSubView sectionize 'Integrations', HomeAccountIntegrationsView

    @wrapper.addSubView headerize 'Sessions'
    @wrapper.addSubView sectionize 'Sessions', HomeAccountSessionsView

