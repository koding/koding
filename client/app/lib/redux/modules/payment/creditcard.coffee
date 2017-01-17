kd = require 'kd'
_ = require 'lodash'
immutable = require 'app/util/immutable'

reduxHelper = require 'app/redux/helper'

schemas = require './schemas'

customer = require './customer'
info = require './info'

withNamespace = reduxHelper.makeNamespace 'koding', 'payment', 'creditcard'

REMOVE = reduxHelper.expandActionType withNamespace 'REMOVE'
HAS_CARD = reduxHelper.expandActionType withNamespace 'HAS_CARD'
AUTHORIZE = reduxHelper.expandActionType withNamespace 'AUTHORIZE'

reducer = (state = null, action) ->

  { normalize } = reduxHelper

  switch action.type

    when customer.LOAD.SUCCESS, customer.CREATE.SUCCESS, customer.UPDATE.SUCCESS
      normalized = normalize action.result, schemas.customer
      c = normalized.first 'customer'

      if c.default_source
        return normalized.entities.sources[c.default_source]

    when info.LOAD.SUCCESS
      normalized = normalize action.result, schemas.info
      c = normalized.first 'customer'

      if c.default_source
        return normalized.entities.sources[c.default_source]

    when HAS_CARD.SUCCESS
      # we are returning an empty object here so that other parts
      # of the system can know that there is a credit card
      # available. This is for when a member loads the site, but
      # doesn't know if the team is disabled or not. And this makes
      # sure that, they only know that there is a credit card, but
      # there is no info available for them.
      return if state then state else immutable {}

    when REMOVE.SUCCESS, HAS_CARD.FAIL, customer.REMOVE.SUCCESS
      return null

  return state


remove = ->
  return {
    types: [ REMOVE.BEGIN, REMOVE.SUCCESS, REMOVE.FAIL ]
    payment: (service) -> service.deleteCreditCard()
  }

hasCreditCard = ->
  return {
    types: [ HAS_CARD.BEGIN, HAS_CARD.SUCCESS, HAS_CARD.FAIL ]
    payment: (service) -> service.hasCreditCard()
  }

authorize = ({ source, email }) ->
  return {
    types: [ AUTHORIZE.BEGIN, AUTHORIZE.SUCCESS, AUTHORIZE.FAIL ]
    payment: (service) -> service.authorize { source, email }
  }


creditCard = (state) -> state.creditCard


module.exports = {
  namespace: withNamespace()
  reducer

  creditCard

  remove, hasCreditCard, authorize
  REMOVE, HAS_CARD, AUTHORIZE
}
