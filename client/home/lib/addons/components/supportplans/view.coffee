React = require 'app/react'
SupportPlansBanner = require './components/supportplansbanner'
SupportPlansList = require './components/supportplanslist'
SupportPlansBusinessAddOnBanner = require './components/supportplansbusinessaddonbanner'
SupportPlanDeactivation = require './components/supportplandeactivation'

class SupportPlans extends React.Component


  render: ->

    <div className='support-plans-container'>
      {
        <SupportPlansBanner />  unless @props.activeSupportPlan
      }
      <SupportPlansList
        plans={@props.plans}
        activeSupportPlan={@props.activeSupportPlan}
        onActivateSupportPlan={@props.onActivateSupportPlan}
        onUpdateSupportPlan={@props.onUpdateSupportPlan} />
      <SupportPlansBusinessAddOnBanner />
      {
        <SupportPlanDeactivation
          activeSupportPlan={@props.activeSupportPlan}
          onDeactivateSupportPlan={@props.onDeactivateSupportPlan} />  if @props.activeSupportPlan
        }
    </div>


  module.exports = SupportPlans
