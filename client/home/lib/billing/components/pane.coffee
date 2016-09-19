React = require 'react'
{ connect } = require 'react-redux'

SubscriptionSection = require './subscriptioncontainer'
PaymentSection = require './paymentsectioncontainer'

customer = require 'app/redux/modules/payment/customer'
subscription = require 'app/redux/modules/payment/subscription'
bongo = require 'app/redux/modules/bongo'


class BillingPane extends React.Component

  constructor: (props) ->
    super props
    @state = { loading: off }

  render: ->

    <div>
      <SubscriptionSection loading={@state.loading} />
      <PaymentSection loading={@state.loading} />
    </div>


BillingPane.defaultProps =
  onClickViewMembers: ->


mapDispatchToProps = (dispatch) ->
  return {
    onClickTakeSurvey: ->
    onClickPricingDetails: ->
    onClickViewMembers: ->
  }

module.exports = connect(null, mapDispatchToProps)(BillingPane)
