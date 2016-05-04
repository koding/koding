kd                    = require 'kd'
whoami                = require 'app/util/whoami'
actions               = require './actiontypes'
fetchAccount          = require 'app/util/fetchAccount'
showErrorNotification = require 'app/util/showErrorNotification'
showNotification      = require 'app/util/showNotification'
impersonate           = require 'app/util/impersonate'
getMessageOwner       = require 'app/util/getMessageOwner'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...

###*
 * Load account with given id.
 *
 * @param {string} id
###
loadAccount = (id) ->

  new Promise (resolve, reject) ->

    origin = generateOrigin id

    { reactor } = kd.singletons

    reactor.dispatch actions.LOAD_USER_BEGIN, { id, origin }

    fetchAccount origin, (err, account) ->
      if err
        reactor.dispatch actions.LOAD_USER_FAIL, { err, id, origin }
        reject { err, id }
        return

      reactor.dispatch actions.LOAD_USER_SUCCESS, { id, origin, account }

      resolve { account }


###*
 * Generate an origin object for given id.
 *
 * @param {string} id - JAccount id
 * @return {object}
 * @api private
###
generateOrigin = (id) -> { id, constructorName: 'JAccount', _id: id }


searchAccounts = (query, options = {}) ->

  { SEARCH_USERS_BEGIN
    SEARCH_USERS_SUCCESS
    SEARCH_USERS_FAIL } = actions

  { reactor } = kd.singletons

  reactor.dispatch SEARCH_USERS_BEGIN, { query }

  kd.singletons.search.searchAccounts(query, options)
    .then (users) ->
      reactor.dispatch SEARCH_USERS_SUCCESS, { users }
    .catch (err) ->
      reactor.dispatch SEARCH_USERS_FAIL, { err, query }


showMarkUserAsTrollSuccess = (account) ->

  showNotification "@#{account.profile.nickname} marked as a troll!"


showMarkUserAsTrollFail = (err, account) ->

  showErrorNotification err, { userMessage: 'You are not allowed to mark this user as a troll!' }


showUnmarkUserAsTrollSuccess = (account) ->

  showErrorNotification "@#{account.profile.nickname} won't be treated as a troll anymore!"


showBlockUserFail = (err, account) ->

  showErrorNotification err, { userMessage: 'You are not allowed to block user!' }


showBlockUserSuccess = (account) ->

  showNotification 'User is blocked!'


###*
 * Action to mark user as troll
###
markUserAsTroll = (account) ->

  { MARK_USER_AS_TROLL_BEGIN
    MARK_USER_AS_TROLL_SUCCESS
    MARK_USER_AS_TROLL_FAIL } = actions

  dispatch MARK_USER_AS_TROLL_BEGIN, account

  account.markUserAsExempt yes, (err, res) ->
    if err
      dispatch MARK_USER_AS_TROLL_FAIL, { err, account }
      showMarkUserAsTrollFail err, account
      return

    dispatch MARK_USER_AS_TROLL_SUCCESS, account
    showMarkUserAsTrollSuccess account


###*
 * Action to unmark user as troll
###
unmarkUserAsTroll = (account) ->

  { UNMARK_USER_AS_TROLL_BEGIN
    UNMARK_USER_AS_TROLL_SUCCESS
    UNMARK_USER_AS_TROLL_FAIL } = actions

  dispatch UNMARK_USER_AS_TROLL_BEGIN, account

  account.markUserAsExempt no, (err, res) ->
    if err
      dispatch UNMARK_USER_AS_TROLL_FAIL, { err, account }
      showMarkUserAsTrollFail err, account
      return

    dispatch UNMARK_USER_AS_TROLL_SUCCESS, account
    showUnmarkUserAsTrollSuccess account


###*
 * Action to block user
###
blockUser = (account, blockingTime) ->

  { BLOCK_USER_BEGIN, BLOCK_USER_SUCCESS, BLOCK_USER_FAIL } = actions

  dispatch BLOCK_USER_BEGIN, account

  whoami().blockUser account._id, blockingTime, (err, res) ->

    if err
      dispatch BLOCK_USER_FAIL, { err, account }
      showBlockUserFail err, account
    else
      dispatch BLOCK_USER_SUCCESS, account
      showBlockUserSuccess()


###*
 * Action to impersonate user
###
impersonateUser = (message) ->

  getMessageOwner message, (err, owner) ->

    return if err
    impersonate owner.profile.nickname


###*
 * Action to set delete flag for create channel modal dropdown selected users to delete
###
markParticipantMayBeDeleted = (accountId) ->

  { SET_CREATE_CHANNEL_PARTICIPANT_DELETE_FLAG } = actions
  dispatch SET_CREATE_CHANNEL_PARTICIPANT_DELETE_FLAG, { accountId }


###*
 * Action to unset delete flag for create channel modal dropdown selected users
###
unmarkParticipantMayBeDeleted = (accountId) ->

  { UNSET_CREATE_CHANNEL_PARTICIPANT_DELETE_FLAG } = actions
  dispatch UNSET_CREATE_CHANNEL_PARTICIPANT_DELETE_FLAG, { accountId }


loadLoggedInUserEmail = ->

  { reactor } = kd.singletons
  whoami().fetchEmail (err, email) ->
    reactor.dispatch actions.LOAD_LOGGED_IN_USER_EMAIL_SUCCESS, { email }


module.exports = {
  loadAccount
  searchAccounts
  markUserAsTroll
  unmarkUserAsTroll
  blockUser
  impersonateUser
  markParticipantMayBeDeleted
  unmarkParticipantMayBeDeleted
  loadLoggedInUserEmail
}
