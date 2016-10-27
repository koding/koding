globals = require 'globals'
isAdmin = require 'app/util/isAdmin'

{ LOAD: BONGO_LOAD } = bongo = require 'app/redux/modules/bongo'
{ Plan } = require 'app/redux/modules/payment/constants'

{ create: createCustomer } = require 'app/redux/modules/payment/customer'
{ load: loadPaymentInfo } = require 'app/redux/modules/payment/info'
{ load: loadInvoices } = require 'app/redux/modules/payment/invoices'

{
  load: loadSubscription
  create: createSubscription
} = require 'app/redux/modules/payment/subscription'

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

  # this case is for the groups that are registered before we activated new
  # payment system for teams. Once we send an info call, our backend will
  # ensure that the team made the call has a `payment` property. But it will
  # not be realtime, reloading it to get the group with `payment` property from
  # the payload. ~Umut
  handleNoPaymentAdmin = ->
    console.info 'Got an old team, we need to reload'
    return location.reload()

  # This is for members of the existing groups prior to pricing release.
  # We will create customer & subscription and then `NEEDS_UPGRADE` modal will
  # be shown to the user. All actions going from there will reload the page,
  # and the group will be activated. ~Umut
  handleNoPaymentMember = ->
    dispatch(createCustomer()).then ->
      dispatch(createSubscription(
        getState().customer.id, Plan.UP_TO_10_USERS
      ))

  if isAdmin()
    dispatch(loadPaymentInfo())
      .then ->
        unless globals.currentGroup.payment
          return handleNoPaymentAdmin()
      .then -> dispatch(loadInvoices())
  else
    if globals.currentGroup.payment
    then dispatch(loadSubscription())
    else handleNoPaymentMember()



module.exports = dispatchInitialActions = (store) ->

  { getState, dispatch } = store

  console.log 'dispatching initial actions', store

  promise = loadAccount(store)
    .then -> loadGroup(store)
    .then -> loadUserDetails(store)
    .then -> ensurePaymentDetails(store)

  promise.then(console.log.bind(console, 'finished dispatching initial actions'))


