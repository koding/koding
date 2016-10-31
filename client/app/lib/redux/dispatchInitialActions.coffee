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

  # NOTE:
  #
  # `handleNoPayment{Admin,Member}` functions are for the cases where an
  # existing team prior to our pricing release. Here are the expected
  # behaviors:
  #   - Admin:  First login will trigger the group plan creation process in the
  #             backend. And don't have to do anything, the next time a new
  #             member/admin is logged in everything will be ok. First logged
  #             in will see a notification modal.
  #
  #   - Member: First login will trigger a customer/subscription process in
  #             client side, not in backend. If things go smoothly members
  #             shouldn't see anything and continue using Koding immediately.

  handleNoPaymentAdmin = ->
    # do nothing, we will show a modal, and doing any action over there will
    # trigger a reload which should fix the problem.
    console.info 'Got an old team, we need to reload'

  handleNoPaymentMember = ->
    # create customer & subscription
    # then reload the page, in next reload, group will have `payment` object
    # ready.
    dispatch(createCustomer())
      .then -> dispatch(createSubscription getState().customer.id, Plan.UP_TO_10_USERS)
      .then -> location.reload()

  if isAdmin()

    promise = dispatch(loadPaymentInfo())

    if globals.currentGroup.payment
    then promise.then -> dispatch(loadInvoices())
    else handleNoPaymentAdmin()

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


