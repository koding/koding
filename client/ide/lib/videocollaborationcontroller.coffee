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


  leaveVideoCollaboration: ->


  switchToUserVideo: (nickname) ->

    @videoModel.changeActiveParticipant nickname


  muteParticipant: (participant) ->

    # @videoModel.muteParticipant participant


  unmuteParticipant: (participant) ->

    # @videoModel.unmuteParticipant participant


  turnOffParticipantCamera: (participant) ->

    # @videoModel.disableParticipantCamera participant


  turnOnParticipantCamera: (participant) ->

    # @videoModel.enableParticipantCamera participant


  turnOffCamera: ->

    # @videoModel.disableParticipantCamera nick()


  turnOnCamera: ->

    # @videoModel.enableParticipantCamera nick()


  handleVideoAccessQuestionAsked: ->


  handleVideoAccessQuestionAnswered: ->


  handleVideoEnded: ->


  handleVideoActive: (publisher) ->

    @chat.emit 'VideoCollaborationActive', publisher


  handleVideoParticipantJoined: (participant) ->

    @statusBar.emit 'VideoParticipantDidJoin', participant
    @chat.emit 'VideoParticipantDidJoin', participant


  handleVideoParticipantLeft: (participant) ->

    @statusBar.emit 'VideoParticipantDidLeave', participant
    @chat.emit 'VideoParticipantDidLeave', participant


  handleVideoActiveParticipantChanged: (participant) ->

    @statusBar.emit 'VideoActiveParticipantDidChange', participant
    @chat.emit 'VideoActiveParticipantDidChange', participant


  handleVideoParticipantAudioStateChanged: (participant, state) ->

    @statusBar.emit 'VideoParticipantAudioStateDidChange', participant, state
    @chat.emit 'VideoParticipantAudioStateDidChange', participant, state


  handleVideoParticipantCameraStateChanged: (participant, state) ->

    @statusBar.emit 'VideoParticipantCameraStateDidChange', participant, state
    @chat.emit 'VideoParticipantCameraStateDidChange', participant, state


