actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to handle channel participants dropdown visibility flag
###
module.exports = class ChannelParticipantsDropdownVisibilityStore extends KodingFluxStore

  @getterPath = 'ChannelParticipantsDropdownVisibilityStore'


  getInitialState: -> no


  initialize: ->

    @on actions.SET_CHANNEL_PARTICIPANTS_DROPDOWN_VISIBILITY, @setVisibility


  ###*
   * It updates current visibility flag with a given value
   *
   * @param {number} currentState
   * @param {object} payload
   * @param {bool} payload.visible
   * @return {bool} nextState
  ###
  setVisibility: (currentState, { visible }) -> visible
