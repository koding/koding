kd = require 'kd'
React = require 'kd-react'
KDReactorMixin = require 'app/flux/base/reactormixin'
PaymentFlux = require 'app/flux/payment'
PlansList = require './view'


module.exports = class PlansListContainer extends React.Component

  getDataBindings: ->
    return {
      plans: PaymentFlux.getters.groupPlans
    }


  constructor: (props) ->

    super props

    @state = { groupPlans: null }


  render: ->
    <PlansList plans={@state.plans} />


PlansListContainer.include [KDReactorMixin]
