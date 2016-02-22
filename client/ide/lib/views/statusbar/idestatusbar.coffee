kd                     = require 'kd'
nick                   = require 'app/util/nick'
KDView                 = kd.View
KDButtonView           = kd.ButtonView
CustomLinkView         = require 'app/customlinkview'
KDCustomHTMLView       = kd.CustomHTMLView
HelpSupportModal       = require 'app/commonviews/helpsupportmodal'
IDEStatusBarAvatarView = require './idestatusbaravatarview'
isSoloProductLite      = require 'app/util/issoloproductlite'
isPlanFree             = require 'app/util/isPlanFree'
isKoding               = require 'app/util/isKoding'

module.exports = class IDEStatusBar extends KDView

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

    @addSubView @status = new KDCustomHTMLView cssClass : 'status'

    @addSubView @collaborationStatus = new KDCustomHTMLView
      cssClass: 'hidden collab-status'
      partial : 'Collaboration session is <span>active</span><i></i>'
      click   : (e) => @toggleSessionEndButton()  if e.target.tagName is 'SPAN'

    @collaborationStatus.addSubView @collaborationEndButtonContainer = new KDCustomHTMLView
      cssClass : 'button-container hidden'

    @collaborationEndButtonContainer.addSubView @collaborationEndButton = new KDButtonView
      title    : 'END SESSION'
      cssClass : 'compact solid red end-session'
      callback : @bound 'handleSessionEnd'

    @addSubView new KDCustomHTMLView
      tagName  : 'i'
      cssClass : 'icon help'
      click    : -> new HelpSupportModal

    @addSubView new KDCustomHTMLView
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
            @share = new KDCustomHTMLView { cssClass: 'hidden' }
            @addSubView @share
          else
            @addSubView @share
      else
        @addSubView @share
    else
      @addSubView @share

    @addSubView @avatars = new KDCustomHTMLView cssClass : 'avatars fr hidden'

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

    @status.show()
    @collaborationStatus.hide()
    @collaborationEndButtonContainer.setClass 'hidden'
    @collaborationStatus.unsetClass 'participant'
    @participantAvatars = {}


  handleCollaborationStarted: ->

    @share.setClass      'active'
    @share.unsetClass    'loading'
    @share.unsetClass    'not-started'
    @share.updatePartial 'Chat'

    @status.hide()
    @collaborationStatus.show()

    unless @amIHost_()
      @collaborationEndButton.setTitle 'LEAVE SESSION'
      @collaborationStatus.setClass 'participant'


  showSessionEndButton: ->

    @isSessionEndButtonVisible = yes
    @collaborationEndButtonContainer.unsetClass 'hidden'
    @collaborationStatus.setClass 'shown'

    kd.singletons.windowController.addLayer @collaborationStatus
    @collaborationStatus.once 'ReceivedClickElsewhere', =>
      @hideSessionEndButton()


  hideSessionEndButton: ->

    @isSessionEndButtonVisible = no
    @collaborationEndButtonContainer.setClass 'hidden'
    @collaborationStatus.unsetClass 'shown'


  toggleSessionEndButton: ->

    if   @isSessionEndButtonVisible then @hideSessionEndButton()
    else @showSessionEndButton()


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
