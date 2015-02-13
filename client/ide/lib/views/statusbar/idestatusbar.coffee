kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDView = kd.View
nick = require 'app/util/nick'
HelpSupportModal = require 'app/commonviews/helpsupportmodal'
CustomLinkView = require 'app/customlinkview'
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
    @on 'CollaborationEnded',   @bound 'handleCollaborationEnded'
    @on 'CollaborationStarted', @bound 'handleCollaborationStarted'
    @on 'ParticipantWatched',   @bound 'decorateWatchedAvatars'
    @on 'ParticipantUnwatched', @bound 'decorateUnwatchedAvatars'

    { mainController } = kd.singletons
    collabDisabled     = mainController.isFeatureDisabled 'collaboration'

    @addSubView @status = new KDCustomHTMLView cssClass : 'status'

    @addSubView new KDCustomHTMLView
      partial  : '<cite></cite>'
      cssClass : 'icon help'
      click    : -> new HelpSupportModal

    @addSubView new KDCustomHTMLView
      partial  : '<cite></cite>'
      cssClass : 'icon github'
      click    : -> kd.utils.createExternalLink 'https://github.com/koding/IDE'

    @addSubView new KDCustomHTMLView
      partial  : '<cite></cite>'
      cssClass : 'icon shortcuts'
      click    : -> kd.getSingleton('appManager').tell 'IDE', 'showShortcutsView'

    @addSubView @share = new CustomLinkView
      href     : "#{kd.singletons.router.getCurrentPath()}/share"
      title    : 'Share'
      cssClass : 'share fr hidden'
      click    : (event) ->
        kd.utils.stopDOMEvent event
        appManager.tell 'IDE', 'showChat'  unless collabDisabled

    @addSubView @avatars = new KDCustomHTMLView cssClass : 'avatars fr'

    @avatars.hide()  if collabDisabled



  showInformation: ->

    @status.updatePartial 'Click the plus button above to create a new panel'


  createParticipantAvatar: (nickname, isOnline) ->

    return  if @participantAvatars[nickname]

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

    oldAvatar = @participantAvatars[nickname]

    if oldAvatar
      oldAvatar.unsetClass 'offline'
      oldAvatar.setClass   'online'
    else
      @createParticipantAvatar nickname, yes

    @avatars.show()


  handleCollaborationEnded: ->

    @share.updatePartial 'Share'
    @avatars.destroySubViews()


  handleCollaborationStarted: ->

    @share.updatePartial 'Chat'
