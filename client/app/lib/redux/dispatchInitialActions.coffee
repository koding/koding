globals = require 'globals'
isAdmin = require 'app/util/isAdmin'

{ LOAD: BONGO_LOAD } = bongo = require 'app/redux/modules/bongo'
customer = require 'app/redux/modules/payment/customer'
{ Plan } = require 'app/redux/modules/payment/constants'

{ load: loadPaymentInfo } = require 'app/redux/modules/payment/info'
{ load: loadSubscription } = require 'app/redux/modules/payment/subscription'
{ load: loadInvoices } = require 'app/redux/modules/payment/invoices'

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
    dispatch(loadPaymentInfo())
      .then ->
        # this case is for the groups that are registered before we activated
        # new payment system for teams. Once we send an info call, our backend
        # will ensure that the team made the call has a `payment` property. But
        # it will not be realtime, reloading it to get the group with `payment`
        # property from the payload. ~Umut
        unless globals.currentGroup.payment
          console.info 'Got an old team, we need to reload'
          return location.reload()
      .then -> dispatch(loadInvoices())
  else
    dispatch(loadSubscription())


module.exports = dispatchInitialActions = (store) ->

  { getState, dispatch } = store

  console.log 'dispatching initial actions', store

  promise = loadAccount(store)
    .then -> loadGroup(store)
    .then -> loadUserDetails(store)
    .then -> ensurePaymentDetails(store)

  promise.then(console.log.bind(console, 'finished dispatching initial actions'))


