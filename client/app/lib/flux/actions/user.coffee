kd           = require 'kd'
actions      = require './actiontypes'
fetchAccount = require 'app/util/fetchAccount'


###*
 * Load account with given id.
 *
 * @param {string} id
###
loadAccount = (id) ->

  origin = generateOrigin id

  { reactor } = kd.singletons

  reactor.dispatch actions.LOAD_USER_BEGIN, { id, origin }

  fetchAccount origin, (err, account) ->
    if err
      reactor.dispatch actions.LOAD_USER_FAIL, { err, id, origin }
      return

    reactor.dispatch actions.LOAD_USER_SUCCESS, { id, origin, account }


###*
 * Generate an origin object for given id.
 *
 * @param {string} id - JAccount id
 * @return {object}
 * @api private
###
generateOrigin = (id) -> { id, constructorName: 'JAccount', _id: id }


loadAccounts = (query, options = {}) ->

  { LOAD_USERS_BEGIN
    LOAD_USERS_SUCCESS
    LOAD_USERS_FAIL } = actions

  { reactor } = kd.singletons

  reactor.dispatch LOAD_USERS_BEGIN, { query }

  group    = kd.getSingleton('groupsController').getCurrentGroup()
  selector = query ? ''
  group.searchMembers selector, options, (err, users) ->
    if err
      reactor.dispatch LOAD_USERS_FAIL, { err, query }
      return

    reactor.dispatch LOAD_USERS_SUCCESS, { users }


module.exports = {
  loadAccount
  loadAccounts
}

