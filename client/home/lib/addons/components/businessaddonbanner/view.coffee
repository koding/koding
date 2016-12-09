React = require 'app/react'
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

module.exports = class BusinessAddOnBanner extends React.Component

  constructor: (props) ->

    super props

    @state = 
      activationModalOpen : no
      businessAddOnActivated : @getBusinessAddOnState()
    @price = '5,000'


  getBusinessAddOnState: ->

    return no


  toggleActivationModal: ->

    @setState {
      activationModalOpen : not @state.activationModalOpen
    }


  activateBusinessAddOn: ->

    @setState { businessAddOnActivated : yes }
    @toggleActivationModal()


  handleActivationButtonClick: ->

    @toggleActivationModal()


  render: ->

    <div>
      {
        <Banner
          type="primary"
          image="banner_business_add_on"
          className="Banner">
          <Container>
            <Header
              heading="Empower Your Koding with"
              target="Business Add-On"/>
            <Message>
              Fusce dapibus, tellus ac cursus commodo, tortor mauriscondimentum nibh, ut fermentum massa justo sit amet risus.
            </Message>
            <Divider />
            <List
              title="Features"
              items={[
                "Try on Koding functionality"
                "Direct communication with leads through <br/> Intercom and Chatlio Integration"
                "Analytics (Coming soon)"
              ]} />
            <Footer>
              <a href="/Home/add-ons/business-add-on#koding-button">See what you will get with Business Add-On below</a>
            </Footer>
          </Container>
          <Actions className="Actions">
            <PriceSegment
              price={@price}
              onClick={@bound 'handleActivationButtonClick'} 
              link="https://www.koding.com/pricing"/>
          </Actions>
        </Banner> if not @state.businessAddOnActivated
      }
      <SupportPlanActivationModal
        isOpen={@state.activationModalOpen}
        title="Business Add On"
        image="business_add_on_activation"
        label="Business Add On"
        price={@price}
        shouldCloseOnOverlayClick={yes}
        onCancel={@bound 'toggleActivationModal'}
        onActivateSupportPlanClick={@bound 'activateBusinessAddOn'} />
    </div>
