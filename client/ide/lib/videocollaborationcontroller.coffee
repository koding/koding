kd                              = require 'kd'
VideoCollaborationModel         = require 'app/videocollaboration/model'
socialHelpers                   = require './collaboration/helpers/social'
isVideoFeatureEnabled           = require 'app/util/isVideoFeatureEnabled'
showError                       = require 'app/util/showError'
LimitedVideoCollaborationModal  = require './views/collaboration/limitedvideocollaborationmodal'


generatePayloadFromModel = (model) ->
  return {
    activeParticipant   : model.getActiveParticipant()
    selectedParticipant : model.getSelectedParticipant()
    participants        : model.getParticipants()
  }


# If you want to limit {X} plan, you can add here and `LimitedVideoCollaborationModal.coffee`
PLAN_PARTICIPANT_LIMITS = {
  free : 2
}


module.exports = VideoCollaborationController =


  prepareVideoCollaboration: ->

    { userAgent } = global.navigator

    if /^((?!chrome|android).)*safari/i.test userAgent
      showError """
        The video component is not supported for Safari.<br />
        To enable this functionality, please use Google Chrome or Firefox.
      """
      return

    @videoModel = new VideoCollaborationModel
      channel : @socialChannel
      view    : @chat.getVideoView()

    @videoModel
      .on 'SessionConnected',              @bound 'handleVideoSessionConnected'
      .on 'CameraAccessQuestionAsked',     @bound 'handleVideoAccessQuestionAsked'
      .on 'CameraAccessQuestionAnswered',  @bound 'handleVideoAccessQuestionAnswered'
      .on 'VideoCollaborationActive',      @bound 'handleVideoActive'
      .on 'VideoCollaborationEnded',       @bound 'handleVideoEnded'
      # .on 'ParticipantConnected',          @bound 'handleVideoParticipantConnected'
      # .on 'ParticipantDisconnected',       @bound 'handleVideoParticipantDisconnected'
      # .on 'ParticipantJoined',             @bound 'handleVideoParticipantJoined'
      # .on 'ParticipantLeft',               @bound 'handleVideoParticipantLeft'
      .on 'ActiveParticipantChanged',      @bound 'handleVideoActiveParticipantChanged'
      .on 'SelectedParticipantChanged',    @bound 'handleVideoSelectedParticipantChanged'
      .on 'ParticipantAudioStateChanged',  @bound 'handleVideoParticipantAudioStateChanged'
      .on 'ParticipantCameraStateChanged', @bound 'handleVideoParticipantCameraStateChanged'
      .on 'ParticipantStartedTalking', (participant) =>
        @handleVideoParticipantTalkingStateChanged participant, on
      .on 'ParticipantStoppedTalking', (participant) =>
        @handleVideoParticipantTalkingStateChanged participant, off

    participantEvents = [
      'SelectedParticipantChanged'
      'ParticipantConnected'
      'ParticipantJoined'
      'ParticipantLeft'
      'ParticipantDisconnected'
    ]

    @videoModel.on participantEvents, @bound 'handleVideoParticipantAction'

    @on 'CollaborationDidCleanup', =>
      @videoModel.session?.disconnect()


  fetchVideoParticipants: (callback) ->

    callback @videoModel.getParticipants()


  startVideoCollaboration: ->

    @canUserStartVideo =>
      @videoModel.start()


  endVideoCollaboration: -> @videoModel.end()


  joinVideoCollaboration: -> @videoModel.join()


  leaveVideoCollaboration: -> @videoModel.leave()


  muteParticipant: (nickname) -> @videoModel.muteParticipant nickname


  toggleVideoControl: (type, activeState) ->

    switch type
      when 'audio'   then @videoModel.requestAudioStateChange activeState
      when 'video'   then @videoModel.requestVideoStateChange activeState
      when 'speaker' then @videoModel.requestSpeakerStateChange activeState
      when 'end'     then @endVideoCollaboration()
      when 'leave'   then @leaveVideoCollaboration()


  switchToUserVideo: (nickname) ->

    @videoModel.changeSelectedParticipant nickname


  hasParticipantWithAudio: (nickname, callback) ->

    @videoModel.hasParticipantWithAudio nickname, callback


  handleVideoSessionConnected: (session, videoActive) ->

    isVideoFeatureEnabled (enabled) =>
      return  unless enabled

      if videoActive
        @emitToViews 'VideoSessionConnected', { action: 'join' }
      else
        if @amIHost
          @emitToViews 'VideoSessionConnected', { action: 'start' }


  handleVideoAccessQuestionAsked: ->


  handleVideoAccessQuestionAnswered: ->


  handleVideoEnded: ->
    @emitToViews 'VideoCollaborationEnded'


  handleVideoActive: (publisher) ->
    @emitToViews 'VideoCollaborationActive'


  handleVideoParticipantAction: ->

    payload = generatePayloadFromModel @videoModel
    @emitToViews 'VideoParticipantsDidChange', payload


  handleVideoParticipantConnected: (participant) ->
    @emitToViews 'VideoParticipantDidConnect', participant


  handleVideoParticipantDisconnected: (participant) ->
    @emitToViews 'VideoParticipantDidDisconnect', participant


  handleVideoParticipantJoined: (participant) ->
    @emitToViews 'VideoParticipantDidJoin', participant


  handleVideoParticipantLeft: (participant) ->
    @emitToViews 'VideoParticipantDidLeave', participant


  handleVideoSelectedParticipantChanged: (nickname, isOnline) ->

    unless nickname
      @emitToViews 'VideoSelectedParticipantDidChange', null, null, isOnline
      return

    socialHelpers.fetchAccount nickname, (err, account) =>
      return console.error err  if err
      @emitToViews 'VideoSelectedParticipantDidChange', nickname, account, isOnline


  handleVideoActiveParticipantChanged: (nickname) ->
    socialHelpers.fetchAccount nickname, (err, account) =>
      return console.error err  if err
      @emitToViews 'VideoActiveParticipantDidChange', nickname, account


  handleVideoParticipantAudioStateChanged: (participant, state) ->
    @emitToViews 'VideoParticipantAudioStateDidChange', participant


  handleVideoParticipantCameraStateChanged: (participant, state) ->
    @emitToViews 'VideoParticipantCameraStateDidChange', participant


  handleVideoParticipantTalkingStateChanged: (participant, state) ->
    @emitToViews 'VideoParticipantTalkingStateDidChange', participant, state


  emitToViews: (args...) ->
    @statusBar?.emit args...
    @chat?.emit args...


  canUserStartVideo: (callback = kd.noop, isVideoActive = no) ->

    { paymentController } = kd.singletons

    @whenRealtimeReady =>

      paymentController.subscriptions (err, plan) =>

        return showError err  if err

        { planTitle }     = plan

        # If there isn't any limit according to current plan.
        return callback()  unless PLAN_PARTICIPANT_LIMITS[planTitle]

        limit             = PLAN_PARTICIPANT_LIMITS[planTitle]
        participantsCount = @participants.asArray().length

        if participantsCount > limit or (participantsCount is 2 and isVideoActive)
          @emit 'UserReachedVideoLimit'
          return new LimitedVideoCollaborationModal plan: planTitle

        callback()
