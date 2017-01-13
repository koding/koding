kd                = require 'kd'
AvatarPopup       = require './avatarpopup'
CustomLinkView    = require '../customlinkview'
HelpSupportModal  = require '../commonviews/helpsupportmodal'
isSoloProductLite = require 'app/util/issoloproductlite'

module.exports = class AccountPopup extends AvatarPopup

  constructor: (options = {}, data) ->

    defaultClasses   = if isSoloProductLite() then 'account hidden-notifications' else 'account'
    options.cssClass = kd.utils.curry defaultClasses, options.cssClass

    super options, data

    { groupsController } = kd.singletons

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Koding University'
      href       : 'https://koding.com/docs'
      target     : '_blank'

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Contact support'
      cssClass   : 'bottom-separator support'
      click      : @bound 'goToSupport'

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Account Settings'
      href       : '/Account'
      attributes : { testpath : 'AccountSettingsLink' }
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
      attributes : { testpath : 'logout-link' }

    # FIXME:
    groupsController.ready =>
      group.canEditGroup (err, success) ->
        return  unless success
        dashboardLink.show()  if group.slug is 'koding'
        adminLink.show()


  hide: ->

    super

    @emit 'AvatarPopupShouldBeHidden'


  goToSupport: (event) ->

    kd.utils.stopDOMEvent event
    new HelpSupportModal
    @hide()


  goToAccountSettings: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute '/Account'
    @hide()


  goToDashboard: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute '/Dashboard'
    @hide()


  goToTeamSettings: (event) =>

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute '/Admin'
    @hide()
