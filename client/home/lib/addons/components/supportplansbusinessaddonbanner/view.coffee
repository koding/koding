React = require 'react'
ReactView = require 'app/react/reactview'
Box = require 'lab/Box'
Button = require 'lab/Button'
{Container, Header, Message, Actions} = Banner = require 'lab/Banner'

module.exports = class SupportPlansBusinessAddOnBanner extends ReactView

  renderReact: ->

    <Banner
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
