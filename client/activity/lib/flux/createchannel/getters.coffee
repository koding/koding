immutable                  = require 'immutable'
ActivityFluxGetters        = require 'activity/flux/getters'
calculateListSelectedIndex = require 'activity/util/calculateListSelectedIndex'
getListSelectedItem        = require 'activity/util/getListSelectedItem'
whoami                     = require 'app/util/whoami'


withEmptyMap  = (storeData) -> storeData or immutable.Map()
#withEmptyList = (storeData) -> storeData or immutable.List()

CreateNewChannelParticipantsSearchQueryStore        =['CreateNewChannelParticipantsSearchQueryStore']
CreateNewChannelParticipantsSelectedIndexStore      =['CreateNewChannelParticipantsSelectedIndexStore']
CreateNewChannelParticipantsDropdownVisibilityStore =['CreateNewChannelParticipantsDropdownVisibilityStore']
CreateNewChannelParticipantIdsStore                 =[['CreateNewChannelParticipantIdsStore'], withEmptyMap]


createChannelParticipantsSearchQuery  = CreateNewChannelParticipantsSearchQueryStore


createChannelParticipants = [
  CreateNewChannelParticipantIdsStore
  ActivityFluxGetters.allUsers
  (participantIds, users) ->
    participantIds.map (id) -> users.get id
]


# Returns a list of users depending on the current query
# If query is empty, returns selected channel participants
# Otherwise, returns users filtered by query
createChannelParticipantsInputUsers = [
  ActivityFluxGetters.allUsers
  createChannelParticipants
  createChannelParticipantsSearchQuery
  (users, participants, query) ->
    return immutable.List()  unless query

    query = query.toLowerCase()
    users.toList().filter (user) ->

      # filter not loaded users.
      return no  if participants.get user.get '_id'

      # filter me out.
      return no  if user.get('_id') is whoami()._id

      # get username of current iterated user.
      userName = user.getIn(['profile', 'nickname']).toLowerCase()

      # filter out non matching users.
      return userName.indexOf(query) is 0
]

createChannelParticipantsSelectedIndex = [
  createChannelParticipantsInputUsers
  CreateNewChannelParticipantsSelectedIndexStore
  calculateListSelectedIndex
]

createChannelParticipantsDropdownVisibility = CreateNewChannelParticipantsDropdownVisibilityStore

createChannelParticipantsSelectedItem = [
  createChannelParticipantsInputUsers
  createChannelParticipantsSelectedIndex
  getListSelectedItem
]



module.exports = {

  createChannelParticipants
  createChannelParticipantsSearchQuery
  createChannelParticipantsInputUsers
  createChannelParticipantsSelectedItem
  createChannelParticipantsDropdownVisibility
  createChannelParticipantsSelectedIndex

}

