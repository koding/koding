React = require 'app/react'
SupportPlan = require 'lab/SupportPlan'
SupportPlanActivationModal = require 'lab/SupportPlanActivationModal'
{ connect } = require 'react-redux'
supportplans = require 'app/redux/modules/payment/supportplans'

class SupportPlansList extends React.Component

  constructor: (props) ->

    super props

    @state =
      activationModalOpen : no
      selectedSupportPlan : {}

    @plans = @props.plans


  getActivePlan: ->

    return null


  handleActivationButtonClick: (plan) ->

    @showActivationModal plan


  showActivationModal: (plan) ->

    @setState {
      activationModalOpen : yes
      selectedSupportPlan : plan
    }


  hideActivationModal: ->

    @setState {
      activationModalOpen : no
      selectedSupportPlan : {}
    }


  activateSupportPlan: ->

    if @props.supportPlan
    then @props.onActivateSupportPlan(@state.selectedSupportPlan.name)
    else @props.onUpdateSupportPlan(@state.selectedSupportPlan.name)
    @hideActivationModal()


  # Types:
  #   active
  #   activation
  #   switch
  getActionType: (plan) ->

    activePlan = @props.supportPlan

    return 'activation'  unless activePlan
    return 'active'  if plan is activePlan

    type = switch plan
      when 'Basic' then 'switch'
      when 'Business'
        if activePlan is 'Basic'
        then 'activation'
        else 'switch'
      when 'Enterprise' then 'activation'

    return type

  render: ->

    plans = @plans.map (plan, index) =>

      <div className='SupportPlanSection' key={index}>
        <SupportPlan
          name={plan.name}
          price={plan.price}
          period={plan.period}
          type={@getActionType plan.name}
          features={plan.features}
          onActivationButtonClick={() => @handleActivationButtonClick plan} />
      </div>

    <div>
      {plans}
      <SupportPlanActivationModal
        isOpen={@state.activationModalOpen}
        title='Support Plan'
        image='support_plan_activation'
        label="#{@state.selectedSupportPlan.name} Support Plan"
        price={@state.selectedSupportPlan.price}
        shouldCloseOnOverlayClick={yes}
        onCancel={@bound 'hideActivationModal'}
        onActivateSupportPlanClick={@bound 'activateSupportPlan'} />
    </div>


  mapStateToProps = (state) ->

    return {
      supportPlan: supportplans.getSupportPlan state
    }


  mapDispatchToProps = (dispatch) ->

    return {
      onActivateSupportPlan: (plan) ->
        dispatch(supportplans.create plan)
      onUpdateSupportPlan: (plan) ->
        dispatch(supportplans.update plan)
    }


  module.exports = connect(
    mapStateToProps
    mapDispatchToProps
  )(SupportPlansList)
