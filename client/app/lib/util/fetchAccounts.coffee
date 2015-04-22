fetchAccount = require './fetchAccount'
sinkrow = require 'sinkrow'

###*
 * Currently there is no way to fetch accounts and then do something, this util
 * extends and improves the fetchAccount util one step more, It first fetches all
 * the given accounts associated with given origins, once the fetching is
 * completed it calls the callback with all of the jAccount instances.
 *
 * It only differs from `fetchAccount` util, syntactically, by accepting an
 * array of origin objects / nicknames rather than single origin object / nickname.
 *
 * @param {Array.<(object|string)> origins
 * @param {function(err: object, accounts: Array.<JAccount>)}
###
module.exports = fetchAccounts = (origins, callback) ->

  _accounts = []
  queue = origins.map (origin) -> ->
    fetchAccount origin, (err, account) ->
      return queue.fin err  if err
      _accounts.push account
      queue.fin()

  sinkrow.dash queue, (err) -> callback err, _accounts


