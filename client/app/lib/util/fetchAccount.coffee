remote = require('app/remote').getInstance()

###*
 * Wrapper function around `JAccount#cacheable`
 * It adds a little bit of intelligence around first
 * argument so that, it will fetch the account depending
 * on some other situations.
 *
 * Example:
 *
 *     # it accepts an origin object.
 *     origin = { constructorName: 'JAccount', id: '5asf222141saf' }
 *     loadAccount origin, (err, account) -> console.log account
 *
 *     # or it accepts a username string.
 *     loadAccount 'foo', (err, account) -> console.log account
 *
 *
 * @param {object|string} origin
 * @param {function(err: object, account: JAccount)}
###
module.exports = fetchAccount = (origin, callback) ->

  if origin.constructorName
    remote.cacheable origin.constructorName, origin.id, callback
  else if 'string' is typeof origin
    remote.cacheable origin, (err, [account]) -> callback err, account
  else if origin?.bongo_?.constructorName is 'JAccount'
    callback null, origin
  else
    callback { message: 'utils.fetchAccount: wrong type of argument - origin' }


