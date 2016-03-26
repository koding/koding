kd                     = require 'kd'
JView                  = require 'app/jview'
remote                 = require('app/remote').getInstance()
AvatarView             = require 'app/commonviews/avatarviews/avatarview'
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'
invitationWithNoEmail  = require 'app/util/invitationWithNoEmail'


module.exports = class BlockedMemberItemView extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data

    @avatar = new AvatarView
      size  : { width: 40, height : 40 }
    , @getData()

    @roleLabel = new kd.CustomHTMLView
      cssClass : 'role'
      partial  : "Disabled <span class='settings-icon'></span>"
      click    : @bound 'toggleSettings'

    @createSettingsView()


  createSettingsView: ->

    unless @settings
      @settings  = new kd.CustomHTMLView
        cssClass : 'settings hidden'

    @settings.addSubView @unblockButton = new kd.ButtonView
      cssClass : kd.utils.curry 'solid compact outline blocked'
      title    : 'Enable User'
      loader   : { color: '#444444' }
      callback : @bound 'unblockUser'


  unblockUser: ->

    currentGroup = kd.singletons.groupsController.getCurrentGroup()

    invitationWithNoEmail @getData(), currentGroup,  (err, result) ->

      if err
        customErr = new Error 'Failed to unblock user. Please try again.'
        return @handleError @unblockButton, customErr

      kd.singletons.notificationController.emit 'NewMemberJoinedToGroup'
      @destroy()


  toggleSettings: ->

    @settings.toggleClass  'hidden'
    @roleLabel.toggleClass 'active'


  pistachio: ->
    data     = @getData()
    fullname = getFullnameFromAccount data
    nickname = data.profile.nickname
    email    = data.profile.email

    return """
      <div class="details">
        {{> @avatar}}
        <p class="fullname">#{fullname}</p>
        <p class="nickname">@#{nickname}</p>
      </div>
      <p title="#{email}" class="email">#{email}</p>
      {{> @roleLabel}}
      <div class='clear'></div>
      {{> @settings}}
    """
