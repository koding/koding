kd                     = require 'kd'
nick                   = require 'app/util/nick'
KDView                 = kd.View
KDButtonView           = kd.ButtonView
CustomLinkView         = require 'app/customlinkview'
KDCustomHTMLView       = kd.CustomHTMLView
HelpSupportModal       = require 'app/commonviews/helpsupportmodal'
IDEStatusBarAvatarView = require './idestatusbaravatarview'


module.exports = class IDEStatusBar extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'status-bar'

    super options, data

    {appManager} = kd.singletons

    @participantAvatars = {}

    @on 'ShowAvatars',          @bound 'showAvatars'
    @on 'ParticipantLeft',      @bound 'dimParticipantAvatar'
    @on 'ParticipantJoined',    @bound 'addParticipantAvatar'
    @on 'CollaborationLoading', @bound 'handleCollaborationLoading'
    @on 'CollaborationEnded',   @bound 'handleCollaborationEnded'
    @on 'CollaborationStarted', @bound 'handleCollaborationStarted'
    @on 'ParticipantWatched',   @bound 'decorateWatchedAvatars'
    @on 'ParticipantUnwatched', @bound 'decorateUnwatchedAvatars'

    { mainController, shortcuts } = kd.singletons
    collabDisabled = mainController.isFeatureDisabled 'collaboration'

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
      partial  : '<cite></cite>'
      cssClass : 'icon help'
      click    : -> new HelpSupportModal

    @addSubView new KDCustomHTMLView
      partial  : '<cite></cite>'
      cssClass : 'icon shortcuts'
      click    : -> shortcuts.showModal()

    @addSubView @share = new CustomLinkView
      href     : "#{kd.singletons.router.getCurrentPath()}/share"
      title    : 'Loading'
      cssClass : 'share fr hidden'
      click    : (event) ->
        kd.utils.stopDOMEvent event
        return  if @hasClass 'loading'
        appManager.tell 'IDE', 'showChat'  unless collabDisabled

    @addSubView @avatars = new KDCustomHTMLView cssClass : 'avatars fr'

    @avatars.hide()  if collabDisabled


  showInformation: ->

    @status.updatePartial 'Click the plus button above to create a new panel'


  createParticipantAvatar: (nickname, isOnline) ->

    return  if @participantAvatars[nickname] or nickname is nick()

    view       = new IDEStatusBarAvatarView
      origin   : nickname
      size     : width: 24, height: 24
      cssClass : if isOnline then 'online' else 'offline'

    @participantAvatars[nickname] = view
    @avatars.addSubView view


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
      avatar.setClass   'offline'
      avatar.unsetClass 'online'


  removeParticipantAvatar: (nickname) ->

    @participantAvatars[nickname]?.destroy()
    delete @participantAvatars[nickname]


  addParticipantAvatar: (nickname) ->

    return no  if nickname is nick()

    oldAvatar = @participantAvatars[nickname]

    if oldAvatar
      oldAvatar.unsetClass 'offline'
      oldAvatar.setClass   'online'
    else
      @createParticipantAvatar nickname, yes

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
