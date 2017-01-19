React = require 'react'
Box = require 'lab/Box'
Button = require 'lab/Button'
{Container, Header, Message, Actions} = Banner = require 'lab/Banner'

module.exports = class SupportPlansBusinessAddOnBanner extends React.Component

  render: ->

    <section className='HomeAppView--section support-plans-business-add-on-banner-section'>
      <Banner
        className='support-plans-business-add-on-banner'
        type='primary'>
        <Container>
          <Header
          heading='Are you looking for our'
          target='Business Add-On?'/>
          <Message>
            Fusce dapibus, tellus ac cursus commodo, tortor mauriscondimentum nibh.
          </Message>
        </Container>
        <Actions className='Actions'>
          <a href='/Home/add-ons/business-add-on'><Button type='primary-1' size='medium' auto>EXPLORE</Button></a>
        </Actions>
      </Banner>
    </section>
