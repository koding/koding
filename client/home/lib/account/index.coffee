kd = require 'kd'
headerize = require '../commons/headerize'
sectionize = require '../commons/sectionize'
hasIntegration = require 'app/util/hasIntegration'
HomeAccountEditProfile = require './homeaccounteditprofile'
HomeAccountChangePassword = require './homeaccountchangepassword'
HomeAccountSecurityView = require './homeaccountsecurityview'
HomeAccountIntegrationsView = require './homeaccountintegrationsview'
HomeAccountSessionsView = require './homeaccountsessionsview'
TeamFlux = require 'app/flux/teams'


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

    @integrationHeader  = @wrapper.addSubView \
      headerize 'Integrations'
    @integrationSection = @wrapper.addSubView \
      sectionize 'Integrations', HomeAccountIntegrationsView

    @checkIntegrations()
    kd.singletons.mainController.on 'IntegrationsUpdated', =>
      @checkIntegrations()

    @wrapper.addSubView headerize 'Sessions'
    @wrapper.addSubView sectionize 'Sessions', HomeAccountSessionsView

    @wrapper.addSubView new kd.CustomHTMLView
      cssClass : 'delete-account'
      partial : 'DELETE ACCOUNT'
      click : -> TeamFlux.actions.deleteAccount()


  checkIntegrations: ->
    if (hasIntegration 'gitlab') or (hasIntegration 'github')
      @showIntegrations()
    else
      @hideIntegrations()


  hideIntegrations: ->
    @integrationHeader.hide()
    @integrationSection.hide()


  showIntegrations: ->
    @integrationHeader.show()
    @integrationSection.show()


  handleAnchor: (anchor) ->

    kd.utils.defer ->
      selector = switch anchor
        when '#password'
          '[name=password]'
        when ''
          '[name=firstName]'

      if selector
        document.querySelector(selector).focus?()
