React = require 'app/react'

Box = require 'lab/Box'
Button = require 'lab/Button'
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

  handleActivationButtonClick: ->

    @props.onActivationButtonClick()


  render: ->

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
          price={@props.price}
          onClick={@bound 'handleActivationButtonClick'}
          link='https://www.koding.com/pricing'/>
      </Actions>
    </Banner>

module.exports = BusinessAddOnBanner
