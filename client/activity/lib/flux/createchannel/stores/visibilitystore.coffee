actions        = require 'activity/flux/createchannel/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to handle participants-dropdown of create new channel modal visibility flag
###
module.exports = class CreateNewChannelParticipantsDropdownVisibilityStore extends KodingFluxStore

  @getterPath = 'CreateNewChannelParticipantsDropdownVisibilityStore'


  getInitialState: -> no


  initialize: ->

    @on actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_DROPDOWN_VISIBILITY, @setVisibility


  ###*
   * It sets current visibility with given value
   *
   * @param {bool} currentState
   * @param {object} payload
   * @param {bool} payload.visible
   * @return {bool} nextState
  ###
  setVisibility: (currentState, { visible }) -> visible


