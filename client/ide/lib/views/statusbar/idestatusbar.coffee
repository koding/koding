kd                        = require 'kd'
globals                   = require 'globals'
nick                      = require 'app/util/nick'
CustomLinkView            = require 'app/customlinkview'
IDEStatusBarAvatarView    = require './idestatusbaravatarview'
ButtonViewWithProgressBar = require 'app/commonviews/buttonviewwithprogressbar'

PROGRESS_DELAYS = [
  { delay : 500,  progress : 15 }
  { delay : 1500, progress : 30 }
  { delay : 2500, progress : 75 }
  { delay : 3250, progress : 90 }
]

module.exports = class IDEStatusBar extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'IDE-StatusBar'

    super options, data

    @participantAvatars = {}
    @avatarTimers       = {}

    @on 'ShowAvatars',            @bound 'showAvatars'
    @on 'ParticipantLeft',        @bound 'dimParticipantAvatar'
    @on 'ParticipantJoined',      @bound 'addParticipantAvatar'
    @on 'CollaborationPreparing', @bound 'handleCollaborationPreparing'
    @on 'CollaborationLoading',   @bound 'handleCollaborationLoading'
    @on 'CollaborationEnded',     @bound 'handleCollaborationEnded'
    @on 'CollaborationStarted',   @bound 'handleCollaborationStarted'
    @on 'ParticipantWatched',     @bound 'decorateWatchedAvatars'
    @on 'ParticipantUnwatched',   @bound 'decorateUnwatchedAvatars'

    { mainController, router, appManager } = kd.singletons

    @addSubView @status = new kd.CustomHTMLView { cssClass : 'status' }

    @addSubView @collaborationLinkContainer = new kd.CustomHTMLView
      cssClass: 'collaboration-link-container'

    superKey  = if globals.os is 'mac' then '⌘' else 'CTRL'

    shareCopy = new kd.CustomHTMLView
      partial: ''' <h3>Collaboration session is started. Share link to invite.</h3>
      <p>This is your collaboration link. You can share this link anytime to invite someone to your
      session. Click link to copy!</p>
      '''

    copyLink = new kd.CustomHTMLView
      cssClass: 'copied-link'
      partial: '<strong>Collaboration link is copied to clipboard.</strong>'


    @collaborationLinkContainer.addSubView @collaborationLink = new kd.CustomHTMLView
      cssClass   : 'collaboration-link'
      partial    : ''
      bind       : 'mouseenter mouseleave'
      mouseleave : -> @tooltip.hide()
      mouseenter : ->
        @tooltip.update shareCopy
        @tooltip.setView shareCopy
        @tooltip.show()
        @tooltip.once 'ReceivedClickElsewhere', @tooltip.bound 'hide'

      click      : ->
        link = @getElement()
        @utils.selectText link

        try
          copied = document.execCommand 'copy'
          couldntCopy = "couldn't copy"
          throw couldntCopy  unless copied
        catch
          tooltipPartial = "Hit #{superKey} + C to copy!"

        @tooltip.update copyLink
        @tooltip.setView copyLink
        @tooltip.show()
        @tooltip.once 'ReceivedClickElsewhere', @tooltip.bound 'hide'

    @collaborationLink.setTooltip
      view      : shareCopy
      cssClass  : 'is-light'
      placement : 'above'
      sticky    : yes

    # @addSubView new kd.CustomHTMLView
    #   tagName  : 'i'
    #   cssClass : 'icon help'
    #   click    : -> Intercom?('show')

    @addSubView new kd.CustomHTMLView
      tagName  : 'i'
      cssClass : 'icon shortcuts'
      click    : (event) ->
        kd.utils.stopDOMEvent event
        router.handleRoute '/Shortcuts'

    @addSubView @share = new ButtonViewWithProgressBar
      cssClass        : 'share fr hidden'
      buttonOptions   :
        title         : 'Loading'
        cssClass      : 'start-session transparent'
        callback      : @bound 'handleShareButtonClick'

    @addSubView @video = new CustomLinkView
      href       : '#'
      cssClass   : 'appear-in-button share fr hidden'
      attributes :
        target   : '_blank'
        title    : 'Start a video chat using appear.in'

    @addSubView @avatars = new kd.CustomHTMLView { cssClass : 'avatars fr hidden' }

    mainController.isFeatureDisabled 'collaboration', (collabDisabled) =>
      @_collabDisable = collabDisabled
      @avatars.show()  unless collabDisabled


  handleShareButtonClick: (event) ->

    { appManager } = kd.singletons

    kd.utils.stopDOMEvent event

    return  if @share.hasClass 'loading'
    return  unless appManager.frontApp.isMachineRunning()

    if @share.hasClass 'active'
    then @handleSessionEnd()
    else @startSession()


  startSession: ->

    kd.singletons.appManager.tell 'IDE', 'startCollaborationSession'


  resetProgress: ->

    @share.resetProgress()
    @share.unsetTooltip()


  showInformation: ->

    @status.updatePartial 'Click the plus button above to create a new panel'


  createParticipantAvatar: (nickname, isOnline) ->

    return  if nickname is nick()

    if view = @participantAvatars[nickname]
      return @updateParticipantAvatar view, isOnline

    view       = new IDEStatusBarAvatarView
      origin   : nickname
      size     : { width: 24, height: 24 }
      cssClass : if isOnline then 'online' else 'offline'
      amIHost  : @amIHost_()

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
      { nickname } = account.profile
      isOnline     = onlineUsers.indexOf(nickname) > -1

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


  handlePermissionRequest: (from) ->

    return unless avatarView = @participantAvatars[from]

    avatarView.showRequestPermissionView()


  handleCollaborationPreparing: (tooltipContent) ->

    @share.startProgress()
    @share.updateProgress 0 # Make sure initial value is 0

    PROGRESS_DELAYS.forEach (item) =>
      kd.utils.killWait item.timer  if item.timer # Kill already defined waits
      item.timer = kd.utils.wait item.delay, => @share.updateProgress item.progress

    return  unless tooltipContent

    @share.setTooltip
      view      : new kd.CustomHTMLView
        partial : tooltipContent
      cssClass  : 'is-light collaboration-start-tooltip'
      placement : 'above'
      sticky    : yes
    @share.getTooltip().show()


  handleCollaborationLoading: ->

    if @share
      @share.setClass        'loading'
      @share.unsetClass      'active not-started'
      @share.button.setTitle 'Loading'
      @share.show()
      @resetProgress()

    @video.hide()


  handleCollaborationEnded: ->

    if @share
      @share.setClass        'not-started'
      @share.unsetClass      'active loading red'
      @share.button.setTitle 'START COLLABORATION'
      @resetProgress()

    @avatars.destroySubViews()
    @updateCollaborationLink ''

    @video.hide()
    @status.show()
    @participantAvatars = {}


  handleCollaborationStarted: (options) ->

    if @share
      @share.setClass        'active red'
      @share.unsetClass      'loading not-started green'
      @share.button.setTitle 'END COLLABORATION'
      @resetProgress()

    @video.show()
    @video.setAttribute 'href', "http://appear.in/koding-#{options.channelId}"

    @status.hide()
    @updateCollaborationLink options.collaborationLink

    unless @amIHost_()
      @share?.button.setTitle 'LEAVE SESSION'


  updateCollaborationLink: (collaborationLink) ->

    @collaborationLink.updatePartial collaborationLink
    @collaborationLink.tooltip.show()  if collaborationLink and @amIHost_()


  handleSessionEnd: ->

    @share.setOption 'startProgress', no

    ide = kd.singletons.appManager.getFrontApp()

    if @amIHost_()
    then ide.showEndCollaborationModal()
    else ide.handleParticipantLeaveAction()


  # Obviously hacky way to know the current user is host or not.
  # I know, I said many times not rely frontApp on IDE codebase
  # I think in this case assuming the front app as IDE is safe because
  # it's a user click action. I need to find a better way tho.
  amIHost_ : ->

    return kd.singletons.appManager.getFrontApp().amIHost
