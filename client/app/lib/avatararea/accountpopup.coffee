kd                        = require 'kd'
AvatarPopup               = require './avatarpopup'
CustomLinkView            = require '../customlinkview'
HelpSupportModal          = require '../commonviews/helpsupportmodal'
trackEvent                = require 'app/util/trackEvent'

module.exports = class AccountPopup extends AvatarPopup

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'account', options.cssClass

    super options, data

    { groupsController } = kd.singletons

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Upgrade plan'
      href       : '/Pricing'
      cssClass   : 'bottom-separator'
      click      : @bound 'goToPricing'

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Koding University'
      href       : 'http://learn.koding.com'
      target     : '_blank'

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Contact support'
      cssClass   : 'bottom-separator support'
      click      : @bound 'goToSupport'

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Account Settings'
      href       : '/Account'
      attributes : testpath : 'AccountSettingsLink'
      cssClass   : 'bottom-separator'
      click      : @bound 'goToAccountSettings'

    @avatarPopupContent.addSubView dashboardLink = new CustomLinkView
      title    : 'Group Dashboard'
      href     : '/Dashboard'
      cssClass : 'bottom hidden'
      click    : @bound 'goToDashboard'

    @avatarPopupContent.addSubView adminLink = new CustomLinkView
      title    : 'Team Settings'
      href     : '/Admin'
      cssClass : 'bottom hidden'
      click    : @bound 'goToTeamSettings'

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Logout'
      href       : '/Logout'
      attributes : testpath : 'logout-link'

    # FIXME:
    groupsController.ready ->
      group = groupsController.getCurrentGroup()
      group.canEditGroup (err, success) ->
        return  unless success
        dashboardLink.show()
        adminLink.show()



  hide:->

    super

    @emit 'AvatarPopupShouldBeHidden'


  goToPricing: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute '/Pricing'
    @hide()

    trackEvent 'Account upgrade plan, click',
      category : 'userInteraction'
      action   : 'clicks'
      label    : 'settingsUpgradePlan'


  goToSupport: (event) ->

    kd.utils.stopDOMEvent event
    new HelpSupportModal
    @hide()

    trackEvent 'Contact support, click',
      category : 'userInteraction'
      action   : 'formsubmits'
      label    : 'contactKodingSupport'


  goToAccountSettings: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute '/Account'
    @hide()


  goToDashboard: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute "/Dashboard"
    @hide()


  goToTeamSettings: (event) =>

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute "/Admin"
    @hide()