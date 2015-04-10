VideoCollaborationModel = require 'app/videocollaboration/model'
socialHelpers           = require './collaboration/helpers/social'

module.exports = VideoCollaborationController =

  prepareVideoCollaboration: (channel, view) ->

    @videoModel = new VideoCollaborationModel { channel, view }

    @videoModel
      .on 'CameraAccessQuestionAsked',     @bound 'handleVideoAccessQuestionAsked'
      .on 'CameraAccessQuestionAnswered',  @bound 'handleVideoAccessQuestionAnswered'
      .on 'VideoCollaborationActive',      @bound 'handleVideoActive'
      .on 'VideoCollaborationEnded',       @bound 'handleVideoEnded'
      .on 'ParticipantJoined',             @bound 'handleVideoParticipantJoined'
      .on 'ParticipantLeft',               @bound 'handleVideoParticipantLeft'
      .on 'ActiveParticipantChanged',      @bound 'handleVideoActiveParticipantChanged'
      .on 'SelectedParticipantChanged',    @bound 'handleVideoSelectedParticipantChanged'
      .on 'ParticipantAudioStateChanged',  @bound 'handleVideoParticipantAudioStateChanged'
      .on 'ParticipantCameraStateChanged', @bound 'handleVideoParticipantCameraStateChanged'
      .on 'ParticipantStartedTalking', (participant) =>
        @handleVideoParticipantTalkingStateChanged participant, on
      .on 'ParticipantStoppedTalking', (participant) =>
        @handleVideoParticipantTalkingStateChanged participant, off


  startVideoCollaboration: ->

    @videoModel.start()


  endVideoCollaboration: ->

    @videoModel.end()


  toggleVideoControl: (type, activeState) ->

    switch type
      when 'audio' then @videoModel.setAudioState activeState
      when 'video' then @videoModel.setVideoState activeState
      when 'end'   then @endVideoCollaboration()


  switchToUserVideo: (nickname) ->

    @videoModel.changeSelectedParticipant nickname


  hasParticipantWithAudio: (nickname, callback) ->

    @videoModel.hasParticipantWithAudio nickname, callback


  handleVideoAccessQuestionAsked: ->


  handleVideoAccessQuestionAnswered: ->


  handleVideoEnded: ->
    @emitToViews 'VideoCollaborationEnded'


  handleVideoActive: (publisher) ->
    @emitToViews 'VideoCollaborationActive'


  handleVideoParticipantJoined: (participant) ->
    @emitToViews 'VideoParticipantDidJoin', participant


  handleVideoParticipantLeft: (participant) ->
    @emitToViews 'VideoParticipantDidLeave', participant


  handleVideoSelectedParticipantChanged: (nickname) ->

    unless nickname
      @emitToViews 'VideoSelectedParticipantDidChange', null, null
      return

    socialHelpers.fetchAccount nickname, (err, account) =>
      return console.error err  if err
      @emitToViews 'VideoSelectedParticipantDidChange', nickname, account


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


