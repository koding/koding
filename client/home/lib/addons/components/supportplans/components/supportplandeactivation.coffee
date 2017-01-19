React = require 'app/react'
PlanDeactivation = require '../../plandeactivation'

class SupportPlanDeactivation extends React.Component

  deactivateSupportPlan: ->

    @props.onDeactivateSupportPlan()


  render: ->

    <section className='HomeAppView--section support-plan-deactivation'>
      <PlanDeactivation.Container
          target="#{@props.activeSupportPlan.name} SUPPORT PLAN"
          onDeactivation={@bound 'deactivateSupportPlan'} />
    </section>


  module.exports = SupportPlanDeactivation
