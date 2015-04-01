kd = require 'kd'

module.exports = class VideoCollaborationViewModel extends kd.Object

  constructor: (options = {}, data) ->

    super options, data

    {@view, @model} = options

    @model.on 'ActiveParticipantChanged', @bound 'switchTo'
    @model.on 'VideoCollaborationActive', @bound 'fixParticipantVideoElements'


  ###*
   * First hide all participants, then show participant with given nickname.
   *
   * @param {string} nick
  ###
  switchTo: (nick) ->

    participants = @model.getParticipants()
    participant  = @model.getParticipant nick

    hideAll participants
    showParticipant participant


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

  participant.videoData.element.style.display = 'block'


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

  kd.utils.wait 173, ->
    element = participant.videoData.videoElement()
    element.style.left   = '-14px'
    element.style.height = '265px'
    element.style.width  = '355px'


