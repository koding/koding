kd           = require 'kd'
actions      = require './actiontypes'
fetchAccount = require 'app/util/fetchAccount'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Load account with given id.
 *
 * @param {string} id
###
loadAccount = (id) ->

  origin = generateOrigin id

  dispatch actions.LOAD_USER_BEGIN, { id, origin }

  fetchAccount origin, (err, account) ->
    if err
      dispatch actions.LOAD_USER_FAIL, { err, id, origin }
      return

    dispatch actions.LOAD_USER_SUCCESS, { id, origin, account }


###*
 * Generate an origin object for given id.
 *
 * @param {string} id - JAccount id
 * @return {object}
 * @api private
###
generateOrigin = (id) -> { id, constructorName: 'JAccount', _id: id }

module.exports = {
  loadAccount
}

