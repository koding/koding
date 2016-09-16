globals = require 'globals'
isAdmin = require 'app/util/isAdmin'

{ LOAD: BONGO_LOAD } = bongo = require 'app/redux/modules/bongo'
customer = require 'app/redux/modules/payment/customer'
{ Plan } = require 'app/redux/modules/payment/constants'

{
  load: loadCustomer
  create: createCustomer } = require 'app/redux/modules/payment/customer'

{
  load: loadSubscription
  create: createSubscription } = require 'app/redux/modules/payment/subscription'

loadAccount = ({ dispatch, getState }) ->
  dispatch {
    types: [BONGO_LOAD.BEGIN, BONGO_LOAD.SUCCESS, BONGO_LOAD.FAIL]
    bongo: (remote) -> Promise.resolve(remote.revive globals.userAccount)
  }

loadGroup = ({ dispatch, getState }) -> ->
  dispatch {
    types: [BONGO_LOAD.BEGIN, BONGO_LOAD.SUCCESS, BONGO_LOAD.FAIL]
    bongo: (remote) -> Promise.resolve(remote.revive globals.currentGroup)
  }

loadUserDetails = ({ dispatch, getState }) -> ->
  dispatch {
    types: [BONGO_LOAD.BEGIN, BONGO_LOAD.SUCCESS, BONGO_LOAD.FAIL]
    bongo: (remote) -> remote.api.JUser.fetchUser()
  }

# TODO(umut):
# right now there is no default customer coming from backend.
# if there is no payment information for that group, just create one
ensureCustomer = ({ dispatch, getState }) -> ->

  { _id } = globals.currentGroup

  group = bongo.byId('JGroup', _id)(getState())

  if group.payment
  then dispatch(loadCustomer())
  else dispatch(createCustomer())


ensureSubscription = ({ dispatch, getState }) -> ->

  { _id } = globals.currentGroup

  state = getState()

  group = bongo.byId('JGroup', _id)(state)

  if group.payment?.subscription
  then dispatch(loadSubscription())
  else dispatch(createSubscription(state.customer.id, Plan.UP_TO_10_USERS))


module.exports = dispatchInitialActions = (store) ->

  { getState, dispatch } = store

  console.log 'dispatching initial actions', store

  promise = loadAccount(store)
    .then(loadGroup(store))
    .then(loadUserDetails(store))

  if isAdmin()
    promise = promise
      .then(ensureCustomer(store))
      .then(ensureSubscription(store))

  promise.then(console.log.bind(console, 'finished dispactching initial actions'))


