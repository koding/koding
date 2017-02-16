kd = require 'kd'
globals = require 'globals'
headerize = require '../commons/headerize'
sectionize = require '../commons/sectionize'
hasIntegration = require 'app/util/hasIntegration'
HomeAccountEditProfile = require './homeaccounteditprofile'
HomeAccountChangePassword = require './homeaccountchangepassword'
HomeAccountSecurityView = require './homeaccountsecurityview'
HomeAccountIntegrationsView = require './homeaccountintegrationsview'
HomeAccountSessionsView = require './homeaccountsessionsview'
TeamFlux = require 'app/flux/teams'
TransferOwnershipButton = require './transferownershipbutton'

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

    @wrapper.addSubView actionWrapper = new kd.CustomHTMLView
      cssClass : 'action-wrapper'
    actionWrapper.addSubView new kd.CustomHTMLView
      cssClass : 'delete-account'
      partial : 'DELETE ACCOUNT'
      click : ->
        partial = '<p>
            <strong>CAUTION! </strong>You are going to delete your team. You and your
            team members will not be able to access this team again.
            This action <strong>CANNOT</strong> be undone.
          </p> <br>
          <p>Please enter <strong>current password</strong> into the field below to continue: </p>'

        TeamFlux.actions.deleteAccount(partial)

    if 'owner' in globals.userRoles
      team = kd.singletons.groupsController.getCurrentGroup()
      actionWrapper.addSubView new TransferOwnershipButton {}, team


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
