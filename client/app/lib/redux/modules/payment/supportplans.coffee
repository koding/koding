_ = require 'lodash'

immutable = require 'app/util/immutable'

reduxHelper = require 'app/redux/helper'
schemas = require './schemas'
{ SupportPlans } = require './constants'

withNamespace = reduxHelper.makeNamespace 'koding', 'payment', 'supportplans'

# LOAD = reduxHelper.expandActionType withNamespace 'LOAD'
# CREATE = reduxHelper.expandActionType withNamespace 'CREATE'
# UPDATE = reduxHelper.expandActionType withNamespace 'UPDATE'
# REMOVE = reduxHelper.expandActionType withNamespace 'REMOVE'
LOAD = withNamespace 'LOAD'
CREATE = withNamespace 'CREATE'
UPDATE = withNamespace 'UPDATE'
REMOVE = withNamespace 'REMOVE'

initialState = immutable { plans: SupportPlans, plan: null }

reducer = (state = initialState, action) ->

  { normalize } = reduxHelper

  switch action.type

    when LOAD
      # normalized = normalize action.result, schemas.supportplans
      return state

    when CREATE
      # normalized = normalize action.result, schemas.supportplans
      # return immutable supportplans
      return state.set 'plan', action.plan

    when UPDATE
      # normalized = normalize action.result, schemas.supportplans
      # return immutable supportplans
      return state.set 'plan', action.plan

    when REMOVE
      return state.set 'plan', null

    else
      return state

load = ->
  return {
    # types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
    # payment: (service) -> service.fetchBusinessSupportPlan()
    type: LOAD
  }


create = (plan) ->
  return {
    # types: [CREATE.BEGIN, CREATE.SUCCESS, CREATE.FAIL]
    # payment: (service) -> service.activateSupportPlan()
    type: CREATE
    plan: plan
  }

update = (plan) ->
  return {
    # types: [CREATE.BEGIN, CREATE.SUCCESS, CREATE.FAIL]
    # payment: (service) -> service.activateSupportPlan()
    type: UPDATE
    plan: plan
  }


remove = ->
  return {
    # types: [REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL]
    # payment: (service) -> service.deactivateSupportPlan()
    type: REMOVE
  }


getActiveSupportPlan = (state) -> state.supportplans?.plan

getAllSupportPlans = (state) -> state.supportplans?.plans


module.exports = {
  namespace: withNamespace()
  reducer
  load, create, update, remove
  LOAD, CREATE, UPDATE, REMOVE

  # Selectors
  getActiveSupportPlan, getAllSupportPlans
}
