globals = require 'globals'
isAdmin = require 'app/util/isAdmin'

{ LOAD: BONGO_LOAD } = bongo = require 'app/redux/modules/bongo'
{ Plan, Status } = require 'app/redux/modules/payment/constants'

{ create: createCustomer } = require 'app/redux/modules/payment/customer'
{ load: loadPaymentInfo } = require 'app/redux/modules/payment/info'
{ load: loadInvoices } = require 'app/redux/modules/payment/invoices'
{
load: loadSubscription
create: createSubscription
} = require 'app/redux/modules/payment/subscription'
{ load: loadBusinessAddon } = require 'app/redux/modules/payment/addon'
{ load: loadSupportPlan} = require 'app/redux/modules/payment/supportplans'

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

ensureGroupPayment = ->

  if groupPayment = globals.currentGroup.payment
  then Promise.resolve groupPayment
  else Promise.reject Status.NEEDS_UPGRADE

ensureCreditCard = ({ dispatch }) ->

  if globals.hasCreditCard
  then Promise.resolve()
  else Promise.reject Status.NEEDS_UPGRADE

loadPaymentDetails = ({ dispatch }) ->

  if isAdmin()
  then dispatch(loadPaymentInfo()).then -> dispatch(loadInvoices()).then -> dispatch(loadBusinessAddon()).then -> dispatch(loadSupportPlan())
  else dispatch(loadSubscription())


module.exports = dispatchInitialActions = (store) ->

  { getState, dispatch } = store

  promise = loadAccount(store)
    .then -> loadGroup(store)
    .then -> loadUserDetails(store)
    .then -> ensureGroupPayment()
    .then -> ensureCreditCard(store)
    .then -> loadPaymentDetails(store)

  promise
    .then (args...) -> console.log 'finished dispatching initial actions'
    .catch (err) -> console.info 'error when dispatching initial actions', err
