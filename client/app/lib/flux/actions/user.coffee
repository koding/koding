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

module.exports = {
  loadAccount
}

