kd = require 'kd'
React = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'

CardFormValues = require '../../flux/cardformvalues'

PaymentInformation = require './view'

module.exports = class PaymentInformationContainer extends React.Component

  getDataBindings: ->
    return {
      formValues: CardFormValues.getters.values
    }


  constructor: (props) ->

    super props

    @state = { formValues: null }


  onRemoveCard: ->

    console.log 'onRemoveCard'


  onPaymentHistory: ->

    console.log 'onPaymentHistory'


  onSave: ->

    console.log 'onSave'


  render: ->
    <PaymentInformation
      onInputValueChange={CardFormValues.actions.setValue}
      onRemoveCard={@bound 'onRemoveCard'}
      onPaymentHistory={@bound 'onPaymentHistory'}
      onSave={@bound 'onSave'}
      formValues={@state.formValues} />


PaymentInformationContainer.include [KDReactorMixin]

