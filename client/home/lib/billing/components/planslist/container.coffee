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


  onDetailsClick: (event) ->

    kd.utils.stopDOMEvent event
    window.open 'http://www.koding.com/pricing', '_blank'


  render: ->
    <PlansList
      plans={@state.plans}
      onDetailsClick={@bound 'onDetailsClick'} />


PlansListContainer.include [KDReactorMixin]
