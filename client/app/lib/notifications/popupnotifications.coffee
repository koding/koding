kd                          = require 'kd'
isLoggedIn                  = require '../util/isLoggedIn'
AvatarPopup                 = require '../avatararea/avatarpopup'
isKoding                    = require 'app/util/isKoding'
Tracker                     = require '../util/tracker'



module.exports = class PopupNotifications extends AvatarPopup

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'popup-notifications', options.cssClass

    super options, data

    @notLoggedInMessage = 'Login required to see notifications'


  viewAppended: ->

    super

    @addAccountMenu()  unless isKoding()


  addAccountMenu: ->

    @avatarPopupContent.addSubView ul = new kd.CustomHTMLView
      tagName  : 'ul'
      cssClass : 'popup-settings'
      click    : (event) =>
        if event.target.tagName is 'A' then @hide()
        if event.target.parentElement.className is 'logout'
        then Tracker.track Tracker.USER_LOGGED_OUT
      partial  : """
        <li class='account'><a href='/Account'>Account</a></li>
        <li class='admin hidden'><a href='/Admin'>Team Settings</a></li>
        <li class='support'><a href='https://koding.com/docs'>Support</a></li>
        <li class='logout'><a href='/Logout'>Logout</a></li>
        """

    { groupsController } = kd.singletons
    groupsController.ready ->
      group = groupsController.getCurrentGroup()
      group.canEditGroup (err, success) ->
        unless success
        then ul.$('li.admin').remove()
        else ul.$('li.admin').removeClass('hidden')


  hide: ->
    super


  accountChanged: (account) ->
    super
