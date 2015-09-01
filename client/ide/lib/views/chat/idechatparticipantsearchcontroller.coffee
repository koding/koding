kd                          = require 'kd'
ParticipantSearchController = require 'activity/views/privatemessage/participantsearchcontroller'


module.exports = class IDEChatParticipantSearchController extends ParticipantSearchController


  submitAutoComplete: (item, data) ->

    appManager      = kd.getSingleton 'appManager'
    { videoActive } = @getDelegate()

    appManager.tell 'IDE', 'canUserStartVideo', =>
      ParticipantSearchController::submitAutoComplete.call this, item, data
    , videoActive

