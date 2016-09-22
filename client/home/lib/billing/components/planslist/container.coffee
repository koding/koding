kd = require 'kd'
React = require 'app/react'
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


  onMembersClick: (event) ->

    kd.utils.stopDOMEvent event
    kd.singletons.router.handleRoute '/Home/my-team/teammates'


  onDetailsClick: (event) ->

    kd.utils.stopDOMEvent event
    window.open 'http://www.koding.com/pricing', '_blank'


  render: ->
    <PlansList
      plans={@state.plans}
      onMembersClick={@bound 'onMembersClick'}
      onDetailsClick={@bound 'onDetailsClick'} />


PlansListContainer.include [KDReactorMixin]
