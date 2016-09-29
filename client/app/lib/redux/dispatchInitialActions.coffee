globals = require 'globals'
isAdmin = require 'app/util/isAdmin'

{ LOAD: BONGO_LOAD } = bongo = require 'app/redux/modules/bongo'
customer = require 'app/redux/modules/payment/customer'
{ Plan } = require 'app/redux/modules/payment/constants'

{ load: loadPaymentInfo } = require 'app/redux/modules/payment/info'
{ load: loadSubscription } = require 'app/redux/modules/payment/subscription'

loadAccount = ({ dispatch, getState }) ->
  dispatch {
    types: [BONGO_LOAD.BEGIN, BONGO_LOAD.SUCCESS, BONGO_LOAD.FAIL]
    bongo: (remote) -> Promise.resolve(remote.revive globals.userAccount)
  }

loadGroup = ({ dispatch, getState }) ->
  dispatch {
    types: [BONGO_LOAD.BEGIN, BONGO_LOAD.SUCCESS, BONGO_LOAD.FAIL]
    bongo: (remote) -> Promise.resolve(remote.revive globals.currentGroup)
  }

loadUserDetails = ({ dispatch, getState }) ->
  dispatch {
    types: [BONGO_LOAD.BEGIN, BONGO_LOAD.SUCCESS, BONGO_LOAD.FAIL]
    bongo: (remote) -> remote.api.JUser.fetchUser()
  }

ensurePaymentDetails = ({ dispatch, getState }) ->

  if isAdmin()
  then dispatch(loadPaymentInfo())
  else dispatch(loadSubscription())


module.exports = dispatchInitialActions = (store) ->

  { getState, dispatch } = store

  console.log 'dispatching initial actions', store

  promise = loadAccount(store)
    .then -> loadGroup(store)
    .then -> loadUserDetails(store)
    .then -> ensurePaymentDetails(store)

  promise.then(console.log.bind(console, 'finished dispatching initial actions'))


