React = require 'app/react'

SupportPlanActivationModal = require 'lab/SupportPlanActivationModal'

BusinessAddOnBanner = require './components/businessaddonbanner'
BusinessAddOnKodingButton = require './components/businessaddonkodingbutton'
BusinessAddOnIntercom = require './components/businessaddonintercom'
BusinessAddOnChatlio = require './components/businessaddonchatlio'
BusinessAddOnSupportPlansBanner = require './components/businessaddonsupportplansbanner'
BusinessAddOnDeactivation = require './components/businessaddondeactivation'

class BusinessAddOns extends React.Component

  constructor: (props) ->

    super props
    
    @state =
      modalOpen : no


  toggleActivationModal: ->

    @setState {
      modalOpen : not @state.modalOpen
    }


  activateBusinessAddOn: ->

    @props.onActivateBusinessAddOn()
    @toggleActivationModal()


  handleDeactivationButtonClick: ->

    @props.onDeactivateBusinessAddOn()


  handleActivationButtonClick: ->

    @toggleActivationModal()


  render: ->

    <div className='business-add-ons-container'>
      {
        <div>
          <BusinessAddOnBanner
            price={@props.addonPrice}
            onActivationButtonClick={@bound 'handleActivationButtonClick'} />
           <SupportPlanActivationModal
             isOpen={@state.modalOpen}
             title='Business Add On'
             image='business_add_on_activation'
             label='Business Add On'
             price={@props.addonPrice}
             shouldCloseOnOverlayClick={yes}
             onCancel={@bound 'toggleActivationModal'}
             onActivateSupportPlanClick={@bound 'activateBusinessAddOn'} />
        </div>  unless @props.addonStatus
      }
      <BusinessAddOnKodingButton
        onActivationButtonClick={@bound 'handleActivationButtonClick'}
        addonStatus={@props.addonStatus} />
      <BusinessAddOnIntercom
        onActivationButtonClick={@bound 'handleActivationButtonClick'}
        addonStatus={@props.addonStatus} />
      <BusinessAddOnChatlio
        onActivationButtonClick={@bound 'handleActivationButtonClick'}
        addonStatus={@props.addonStatus} />
      <BusinessAddOnSupportPlansBanner />
      {
        <BusinessAddOnDeactivation
          onDeactivateBusinessAddOn={@bound 'handleDeactivationButtonClick'} />  if @props.addonStatus
      }
    </div>

module.exports = BusinessAddOns
