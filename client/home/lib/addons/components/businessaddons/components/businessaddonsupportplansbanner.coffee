React = require 'react'
Box = require 'lab/Box'
Button = require 'lab/Button'
{Container, Header, Message, Actions} = Banner = require 'lab/Banner'

module.exports = class BusinessAddOnSupportPlansBanner extends React.Component

  render: ->

    <section className='HomeAppView--section business-add-on-support-plans-banner-section'>
      <Banner
        className='business-add-on-support-plans-banner'
        type='success'>
        <Container>
          <Header
            heading='Would you like to explore our'
            target='Powerful Support Plans?'/>
          <Message>
            Fusce dapibus, tellus ac cursus commodo, tortor mauriscondimentum nibh.
          </Message>
        </Container>
        <Actions className='Actions'>
          <a href='/Home/add-ons/support-plans'><Button type='primary-1' size='medium' auto>EXPLORE</Button></a>
        </Actions>
      </Banner>
    </section>
