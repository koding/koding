kd                     = require 'kd'
globals                = require 'globals'
nick                   = require 'app/util/nick'
CustomLinkView         = require 'app/customlinkview'
HelpSupportModal       = require 'app/commonviews/helpsupportmodal'
IDEStatusBarAvatarView = require './idestatusbaravatarview'
isSoloProductLite      = require 'app/util/issoloproductlite'
isPlanFree             = require 'app/util/isPlanFree'
isKoding               = require 'app/util/isKoding'

module.exports = class IDEStatusBar extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'status-bar'

    super options, data

    @participantAvatars = {}
    @avatarTimers       = {}

    @on 'ShowAvatars',          @bound 'showAvatars'
    @on 'ParticipantLeft',      @bound 'dimParticipantAvatar'
    @on 'ParticipantJoined',    @bound 'addParticipantAvatar'
    @on 'CollaborationLoading', @bound 'handleCollaborationLoading'
    @on 'CollaborationEnded',   @bound 'handleCollaborationEnded'
    @on 'CollaborationStarted', @bound 'handleCollaborationStarted'
    @on 'ParticipantWatched',   @bound 'decorateWatchedAvatars'
    @on 'ParticipantUnwatched', @bound 'decorateUnwatchedAvatars'

    { mainController, router, appManager } = kd.singletons

    @addSubView @status = new kd.CustomHTMLView cssClass : 'status'

    @addSubView @collaborationLinkContainer = new kd.CustomHTMLView
      cssClass: 'collaboration-link-container'

    superKey = if globals.os is 'mac' then '⌘' else 'CTRL'

    @collaborationLinkContainer.addSubView @collaborationLink = new kd.CustomHTMLView
      cssClass   : 'collaboration-link'
      partial    : ''
      bind       : 'mouseenter mouseleave'
      mouseleave : -> @tooltip.hide()
      mouseenter : ->
        @tooltip.setTitle 'Click to share!'
        @tooltip.show()
        @tooltip.once 'ReceivedClickElsewhere', @tooltip.bound 'hide'

      click      : ->
        link = @getElement()
        @utils.selectText link

        try
          copied = document.execCommand 'copy'
          throw "couldn't copy"  unless copied
          tooltipPartial = 'Copied to clipboard!'
        catch
          tooltipPartial = "Hit #{superKey} + C to copy!"

        @tooltip.setTitle tooltipPartial
        @tooltip.show()
        @tooltip.once 'ReceivedClickElsewhere', @tooltip.bound 'hide'

    @collaborationLink.setTooltip
      title     : 'Click to share!'
      placement : 'above'
      sticky    : yes



    @addSubView new kd.CustomHTMLView
      tagName  : 'i'
      cssClass : 'icon help'
      click    : -> new HelpSupportModal

    @addSubView new kd.CustomHTMLView
      tagName  : 'i'
      cssClass : 'icon shortcuts'
      click    : (event) =>
        kd.utils.stopDOMEvent event
        router.handleRoute '/Account/Shortcuts'

    @share = new CustomLinkView
      href     : "#{kd.singletons.router.getCurrentPath()}/share"
      title    : 'Loading'
      cssClass : 'share fr hidden'
      click    : (event) ->
        kd.utils.stopDOMEvent event

        return  if @hasClass 'loading'
        return  unless appManager.frontApp.isMachineRunning()

        appManager.tell 'IDE', 'showChat'

    if isKoding()
      if isSoloProductLite()
        isPlanFree (err, isFree) =>
          return  if err
          if isFree
            @share = new kd.CustomHTMLView { cssClass: 'hidden' }
            @addSubView @share
          else
            @addSubView @share
      else
        @addSubView @share
    else
      @addSubView @share

    @addSubView @avatars = new kd.CustomHTMLView cssClass : 'avatars fr hidden'

    mainController.isFeatureDisabled 'collaboration', (collabDisabled) =>
      @_collabDisable = collabDisabled
      @avatars.show()  unless collabDisabled


  showInformation: ->

    @status.updatePartial 'Click the plus button above to create a new panel'


  createParticipantAvatar: (nickname, isOnline) ->

    return  if nickname is nick()

    if view = @participantAvatars[nickname]
      return @updateParticipantAvatar view, isOnline

    view       = new IDEStatusBarAvatarView
      origin   : nickname
      size     : width: 24, height: 24
      cssClass : if isOnline then 'online' else 'offline'

    @participantAvatars[nickname] = view
    @avatars.addSubView view


  updateParticipantAvatar: (view, isOnline) ->

    if isOnline
      view.setClass 'online'
      view.unsetClass 'offline'
    else
      view.setClass 'offline'
      view.unsetClass 'online'


  showAvatars: (accounts, currentlyOnline) ->

    @avatars.show()
    myNickname  = nick()
    onlineUsers = (user.nickname for user in currentlyOnline)

    for account in accounts
      {nickname} = account.profile
      isOnline   = onlineUsers.indexOf(nickname) > -1

      unless nickname is myNickname
        @createParticipantAvatar nickname, isOnline


  decorateWatchedAvatars: (nickname) -> @participantAvatars[nickname]?.setClass 'watching'

  decorateUnwatchedAvatars: (nickname) -> @participantAvatars[nickname]?.unsetClass 'watching'


  dimParticipantAvatar: (nickname) ->

    avatar = @participantAvatars[nickname]

    if avatar
      avatar.setClass 'waiting'
      @avatarTimers[nickname] = kd.utils.wait 15000, ->
        avatar.unsetClass 'online'
        avatar.setClass   'offline'


  removeParticipantAvatar: (nickname) ->

    @participantAvatars[nickname]?.destroy()
    delete @participantAvatars[nickname]


  addParticipantAvatar: (nickname) ->

    return no  if nickname is nick()

    oldAvatar = @participantAvatars[nickname]

    if oldAvatar
      oldAvatar.unsetClass 'offline'
      oldAvatar.unsetClass 'waiting'
      oldAvatar.setClass   'online'

    else
      @createParticipantAvatar nickname, yes

    if timer = @avatarTimers[nickname]
      kd.utils.killWait timer
      delete @avatarTimers[nickname]

    @avatars.show()


  handleCollaborationLoading: ->

    @share.setClass      'loading'
    @share.unsetClass    'active'
    @share.unsetClass    'not-started'
    @share.updatePartial 'Loading'


  handleCollaborationEnded: ->

    @share.setClass      'not-started'
    @share.unsetClass    'loading'
    @share.unsetClass    'active'
    @share.updatePartial 'Share'
    @avatars.destroySubViews()

    @updateCollaborationLink ''

    @status.show()
    @participantAvatars = {}


  handleCollaborationStarted: (options) ->

    @share.setClass      'active'
    @share.unsetClass    'loading'
    @share.unsetClass    'not-started'
    @share.updatePartial 'Chat'

    @status.hide()
    @updateCollaborationLink options.collaborationLink

    unless @amIHost_()


  updateCollaborationLink: (collaborationLink) ->

    @collaborationLink.updatePartial collaborationLink


  handleSessionEnd: ->

    ide = kd.singletons.appManager.getFrontApp()

    if   @amIHost_() then ide.showEndCollaborationModal()
    else ide.handleParticipantLeaveAction nick()


  # Obviously hacky way to know the current user is host or not.
  # I know, I said many times not rely frontApp on IDE codebase
  # I think in this case assuming the front app as IDE is safe because
  # it's a user click action. I need to find a better way tho.
  amIHost_ : ->

    return kd.singletons.appManager.getFrontApp().amIHost
