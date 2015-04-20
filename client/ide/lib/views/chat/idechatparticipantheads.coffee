ParticipantHeads = require 'activity/views/privatemessage/participantheads'
IDEChatMessageParticipantAvatar = require './idechatmessageparticipantavatar'

module.exports = class IDEChatParticipantHeads extends ParticipantHeads

  setDefaultListTitle: ->

    @options.moreListTitle = 'Other Participants'


  setVideoListTitle: ->

    @options.moreListTitle = 'Inactive Participants'


  updateParticipants: (participantMap, state) ->

    @updatePreviewAvatars participantMap.preview, state
    @updateExtras participantMap.hidden, state


  updatePreviewAvatars: (participants, state) ->

    { selectedParticipant, talkingParticipants, videoActive } = state

    avatars = participants.toJS().map (participant) =>
      { nickname } = participant.profile
      cssClasses = []
      if videoActive
        if nickname is selectedParticipant
          cssClasses.push 'is-selectedParticipant'
        if nickname in talkingParticipants
          cssClasses.push 'is-talkingParticipant'

      options = { cssClass: cssClasses.join(' '), size: { width: 25, height: 25 } }
      avatar = new IDEChatMessageParticipantAvatar options, participant
      @forwardEvent avatar, 'ParticipantSelected'

    @previewContainer.destroySubViews()
    @previewContainer.addSubView avatar  for avatar in avatars


