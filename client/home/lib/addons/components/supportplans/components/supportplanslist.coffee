React = require 'app/react'
SupportPlan = require 'lab/SupportPlan'
SupportPlanActivationModal = require 'lab/SupportPlanActivationModal'

class SupportPlansList extends React.Component

  constructor: (props) ->

    super props

    @state =
      activationModalOpen : no
      selectedSupportPlan : {}


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

    if not @props.activeSupportPlan
    then @props.onActivateSupportPlan(@state.selectedSupportPlan)
    else @props.onUpdateSupportPlan(@state.selectedSupportPlan)
    @hideActivationModal()


  # Types:
  #   active
  #   activation
  #   switch
  getActionType: (plan) ->

    activePlan = @props.activeSupportPlan.name  if @props.activeSupportPlan

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

    plans = @props.plans.map (plan, index) =>

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
      <header id='available-plans' className='HomeAppView--sectionHeader'>
        <a href='#available-plans'>Available Plans</a>
      </header>
      <section className='HomeAppView--section support-plans-section'>
        {plans}
      </section>
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


  module.exports = SupportPlansList
