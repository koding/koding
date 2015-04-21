kd = require 'kd'
helper = require './helper'

module.exports = class VideoCollaborationViewModel extends kd.Object

  constructor: (options = {}, data) ->

    super options, data

    {@view, @model} = options

    @model.on 'ActiveParticipantChanged',   @bound 'switchTo'
    @model.on 'VideoCollaborationActive',   @bound 'fixParticipantVideoElements'
    @model.on 'SelectedParticipantChanged', @bound 'switchTo'

    viewControlBinder = (control) => (state) => @view[control].setActiveState state

    @model.on 'VideoPublishStateChanged', viewControlBinder 'controlVideo'
    @model.on 'AudioPublishStateChanged', viewControlBinder 'controlAudio'


  ###*
   * First hide all participants, even the offline ones(!), then show
   * participant with given nickname.
   *
   * @param {string} nick
  ###
  switchTo: (nick) ->

    participants = @model.getParticipants()
    hideAll participants
    hideOfflineUserContainer @view

    if participant = @model.getParticipant nick
    then showParticipant participant
    else showOfflineParticipant @view, nick


  ###*
   * Fix all participant videos.
  ###
  fixParticipantVideoElements: ->

    fixParticipantVideo participant  for _, participant of @model.getParticipants()


###*
 * Hides all participants videos.
 *
 * @param {object<string, ParticipantType.Participant>} participants
###
hideAll = (participants) ->

  hideParticipant participant  for _, participant of participants


###*
 * Hides offline user container.
 *
 * @param {ChatVideoView} view
###
hideOfflineUserContainer = (view) ->

  offlineContainer = view.getOfflineUserContainer()
  offlineContainer.hide()


###*
 * Hides given participant's video element.
 *
 * @param {ParticipantType.Participant} participant
###
hideParticipant = (participant) ->

  participant.videoData.element.style.display = 'none'


###*
 * Shows given participant's video element. Then fixes that participant's video.
 *
 * @param {ParticipantType.Participant} participant
###
showParticipant = (participant) ->

  fixParticipantVideo participant
  participant.videoData.element.style.display = 'block'


###*
 * Shows given participant's avatar on view's offline container.
 *
 * @param {ChatVideoView} view
 * @param {string} nickname
###
showOfflineParticipant = (view, nickname) ->

  offlineContainer = view.getOfflineUserContainer()
  helper.showOfflineParticipant offlineContainer, nickname, kd.noop


###*
 * This is a workaround.
 * This is probably wrong but the way OpenTok sessions are working makes all
 * subscriber videos invisible. This method's pure existence is to get around
 * it. This probably requires a FIXME tag.
 * p.s.: 173 is weird.
 *
 * @param {ParticipantType.Participant} participant
###
fixParticipantVideo = (participant) ->

  fixPoster = (element) ->
    posters = element.querySelectorAll '.OT_video-poster'
    poster.style.backgroundSize = 'cover'  for poster in posters

  fixSize = (element) ->
    element.style.left   = '-14px'
    element.style.height = '265px'
    element.style.width  = '355px'

  kd.utils.wait 173, ->
    element = participant.videoData.videoElement()
    fixSize element

    container = participant.videoData.element
    fixPoster container


