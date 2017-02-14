_ = require 'lodash'

immutable = require 'app/util/immutable'

reduxHelper = require 'app/redux/helper'
schemas = require './schemas'
{AddOns} = require './constants'

withNamespace = reduxHelper.makeNamespace 'koding', 'payment', 'addon'

# LOAD = reduxHelper.expandActionType withNamespace 'LOAD'
# CREATE = reduxHelper.expandActionType withNamespace 'CREATE'
# REMOVE = reduxHelper.expandActionType withNamespace 'REMOVE'
LOAD = withNamespace 'LOAD'
CREATE = withNamespace 'CREATE'
REMOVE = withNamespace 'REMOVE'

initialState = immutable {status: no, addonsPrice: AddOns.price}

reducer = (state = initialState, action) ->
  { normalize } = reduxHelper

  switch action.type

    when LOAD
      # normalized = normalize action.result, schemas.addon
      return state

    when CREATE
      # normalized = normalize action.result, schemas.addon
      # return immutable addon
      return state.set 'status', yes

    when REMOVE
      return state.set 'status', no

    else
      return state


load = ->
  return {
    # types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
    # payment: (service) -> service.fetchBusinessAddon()
    type: LOAD
  }


create = ->
  return {
    # types: [CREATE.BEGIN, CREATE.SUCCESS, CREATE.FAIL]
    # payment: (service) -> service.activateBusinessAddOn()
    type: CREATE
  }


remove = ->
  return {
    # types: [REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL]
    # payment: (service) -> service.deactivateBusinessAddOn()
    type: REMOVE
  }


isActivated = (state) -> state.addon?.status


getAddonPrice = (state) -> state.addon?.addonsPrice


module.exports = {
  namespace: withNamespace()
  reducer
  load, create, remove
  LOAD, CREATE, REMOVE

  # Selectors
  isActivated, getAddonPrice
}
