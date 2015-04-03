VideoCollaborationModel = require 'app/videocollaboration/model'

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
      .on 'ParticipantAudioStateChanged',  @bound 'handleVideoParticipantAudioStateChanged'
      .on 'ParticipantCameraStateChanged', @bound 'handleVideoParticipantCameraStateChanged'


  joinVideoCollaboration: ->

    @videoModel.join()


  startVideoCollaboration: ->

    @videoModel.start()


  endVideoCollaboration: ->

    @videoModel.end()


  toggleVideoControl: (type, activeState) ->

    switch type
      when 'audio' then @videoModel.setAudioState activeState
      when 'video' then @videoModel.setVideoState activeState
      when 'end'   then @endVideoCollaboration()


  leaveVideoCollaboration: ->


  switchToUserVideo: (nickname) ->

    @videoModel.changeActiveParticipant nickname


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


  handleVideoActiveParticipantChanged: (participant) ->
    @emitToViews 'VideoActiveParticipantDidChange', participant


  handleVideoParticipantAudioStateChanged: (participant, state) ->
    @emitToViews 'VideoParticipantAudioStateDidChange', participant


  handleVideoParticipantCameraStateChanged: (participant, state) ->
    @emitToViews 'VideoParticipantCameraStateDidChange', participant


  emitToViews: (args...) ->
    @statusBar.emit args...
    @chat.emit args...


