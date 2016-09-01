kd                        = require 'kd'
globals                   = require 'globals'
nick                      = require 'app/util/nick'
CustomLinkView            = require 'app/customlinkview'
HelpSupportModal          = require 'app/commonviews/helpsupportmodal'
IDEStatusBarAvatarView    = require './idestatusbaravatarview'
isSoloProductLite         = require 'app/util/issoloproductlite'
isPlanFree                = require 'app/util/isPlanFree'
isKoding                  = require 'app/util/isKoding'
ButtonViewWithProgressBar = require 'app/commonviews/buttonviewwithprogressbar'

PROGRESS_DELAYS             = [
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

    @on 'ShowAvatars',          @bound 'showAvatars'
    @on 'ParticipantLeft',      @bound 'dimParticipantAvatar'
    @on 'ParticipantJoined',    @bound 'addParticipantAvatar'
    @on 'CollaborationLoading', @bound 'handleCollaborationLoading'
    @on 'CollaborationEnded',   @bound 'handleCollaborationEnded'
    @on 'CollaborationStarted', @bound 'handleCollaborationStarted'
    @on 'ParticipantWatched',   @bound 'decorateWatchedAvatars'
    @on 'ParticipantUnwatched', @bound 'decorateUnwatchedAvatars'

    { mainController, router, appManager } = kd.singletons

    @addSubView @status = new kd.CustomHTMLView { cssClass : 'status' }

    @addSubView @collaborationLinkContainer = new kd.CustomHTMLView
      cssClass: 'collaboration-link-container'

    superKey  = if globals.os is 'mac' then '⌘' else 'CTRL'
    shareCopy = 'This is your collaboration link. You can share this link to invite someone to your session. Click here to copy!'

    @collaborationLinkContainer.addSubView @collaborationLink = new kd.CustomHTMLView
      cssClass   : 'collaboration-link'
      partial    : ''
      bind       : 'mouseenter mouseleave'
      mouseleave : -> @tooltip.hide()
      mouseenter : ->
        @tooltip.setTitle shareCopy
        @tooltip.show()
        @tooltip.once 'ReceivedClickElsewhere', @tooltip.bound 'hide'

      click      : ->
        link = @getElement()
        @utils.selectText link

        try
          copied = document.execCommand 'copy'
          couldntCopy = "couldn't copy"
          throw couldntCopy  unless copied
          tooltipPartial = 'Copied to clipboard!'
        catch
          tooltipPartial = "Hit #{superKey} + C to copy!"

        @tooltip.setTitle tooltipPartial
        @tooltip.show()
        @tooltip.once 'ReceivedClickElsewhere', @tooltip.bound 'hide'

    @collaborationLink.setTooltip
      title     : shareCopy
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


    if isKoding() and isSoloProductLite()
      isPlanFree (err, isFree) =>
        return  if err
        return  unless isFree

        @share.destroy()
        @share = null

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

    @share.setOption 'startProgress', yes
    @share.updateProgress 0 # Make sure initial value is 0

    PROGRESS_DELAYS.forEach (item) =>
      kd.utils.killWait item.timer  if item.timer # Kill already defined waits
      item.timer = kd.utils.wait item.delay, => @share.updateProgress item.progress

    kd.singletons.appManager.tell 'IDE', 'startCollaborationSession', (err) =>
      @resetProgress()  if err


  resetProgress: -> @share.resetProgress()


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
    else ide.handleParticipantLeaveAction nick()


  # Obviously hacky way to know the current user is host or not.
  # I know, I said many times not rely frontApp on IDE codebase
  # I think in this case assuming the front app as IDE is safe because
  # it's a user click action. I need to find a better way tho.
  amIHost_ : ->

    return kd.singletons.appManager.getFrontApp().amIHost
