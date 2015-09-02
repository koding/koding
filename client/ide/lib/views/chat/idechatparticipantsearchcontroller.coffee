kd                          = require 'kd'
ParticipantSearchController = require 'activity/views/privatemessage/participantsearchcontroller'


module.exports = class IDEChatParticipantSearchController extends ParticipantSearchController


  submitAutoComplete: (item, data) ->

    appManager = kd.getSingleton 'appManager'

    @once 'VideoStateReceived', (videoState) =>

      appManager.tell 'IDE', 'canUserStartVideo', =>
        # I think this usage is more explanatory than `super item, data`
        ParticipantSearchController::submitAutoComplete.call this, item, data
      , videoState

    @emit 'VideoStateRequested'

