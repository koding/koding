React = require 'app/react'
{ connect } = require 'react-redux'
supportplans = require 'app/redux/modules/payment/supportplans'
PlanDeactivation = require '../plandeactivation'

class SupportPlanDeactivation extends React.Component

  constructor: (props) ->

    super props


  deactivateSupportPlan: () ->

    @props.onDeactivateSupportPlan()


  render: ->

    <div>
      {
        <PlanDeactivation.Container
          target="#{@props.supportPlan} SUPPORT PLAN"
          onDeactivation={@bound 'deactivateSupportPlan'} />  if @props.supportPlan
      }
    </div>


  mapStateToProps = (state) ->

    return {
      supportPlan: supportplans.getSupportPlan state
    }


  mapDispatchToProps = (dispatch) ->

    return {
      onDeactivateSupportPlan: ->
        dispatch(supportplans.remove())
    }


  module.exports = connect(
    mapStateToProps
    mapDispatchToProps
  )(SupportPlanDeactivation)
