React = require 'app/react'
{ connect } = require 'react-redux'
addon = require 'app/redux/modules/payment/addon'

Box = require 'lab/Box'
Button = require 'lab/Button'
SupportPlanActivationModal = require 'lab/SupportPlanActivationModal'
{
  Container
  Header
  Message
  Divider
  List
  Footer
  Actions
  PriceSegment
} = Banner = require 'lab/Banner'

class BusinessAddOnBanner extends React.Component

  constructor: (props) ->

    super props

    @price = '5,000'


  getBusinessAddOnState: ->

    return @props.status


  toggleActivationModal: ->

    @props.toggleModal()


  activateBusinessAddOn: ->

    @props.onActivateBusinessAddOn()
    @toggleActivationModal()


  handleActivationButtonClick: ->

    @toggleActivationModal()


  render: ->

    <div>
      {
        <div>
          <Banner
            type='primary'
            image='banner_business_add_on'
            className='Banner'>
            <Container>
              <Header
                heading='Empower Your Koding with'
                target='Business Add-On'/>
              <Message>
                Fusce dapibus, tellus ac cursus commodo, tortor mauriscondimentum nibh, ut fermentum massa justo sit amet risus.
              </Message>
              <Divider />
              <List
                title='Features'
                items={[
                  'Try on Koding functionality'
                  'Direct communication with leads through <br/> Intercom and Chatlio Integration'
                  'Analytics (Coming soon)'
                ]} />
              <Footer>
                <a href='/Home/add-ons/business-add-on#koding-button'>See what you will get with Business Add-On below</a>
              </Footer>
            </Container>
            <Actions className='Actions'>
              <PriceSegment
                price={@price}
                onClick={@bound 'handleActivationButtonClick'}
                link='https://www.koding.com/pricing'/>
            </Actions>
          </Banner>
          <SupportPlanActivationModal
            isOpen={@props.modalOpen}
            title='Business Add On'
            image='business_add_on_activation'
            label='Business Add On'
            price={@price}
            shouldCloseOnOverlayClick={yes}
            onCancel={@bound 'toggleActivationModal'}
            onActivateSupportPlanClick={@bound 'activateBusinessAddOn'} />
        </div>  unless @props.addonStatus
      }
    </div>


  mapStateToProps = (state) ->

    return {
      addonStatus: addon.isActivated state
      modalOpen: addon.modalOpen state
    }


  mapDispatchToProps = (dispatch) ->

    return {
      onActivateBusinessAddOn: ->
        dispatch(addon.create())
      toggleModal: ->
        dispatch(addon.toggleModal())
    }


  module.exports = connect(
    mapStateToProps
    mapDispatchToProps
  )(BusinessAddOnBanner)
