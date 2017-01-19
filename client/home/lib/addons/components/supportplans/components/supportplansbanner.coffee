React = require 'react'
Box = require 'lab/Box'
Button = require 'lab/Button'
{Container, Header, Message, Actions, Footer} = Banner = require 'lab/Banner'

module.exports = class SupportPlansBanner extends React.Component

  render: ->

    <Banner
      type='success'
      image='banner_for_support_plans'
      className='Banner'>
      <Container>
        <Header
          heading='We Are Ready to Help.'
          target='Choose Your Support Plan'/>
        <Message>
          Fusce dapibus, tellus ac cursus commodo, tortor mauriscondimentum nibh, ut fermentum massa justo sit amet risus.
        </Message>
        <Footer>
          <a href='/Home/add-ons/support-plans'>Explore available plans below</a>
        </Footer>
      </Container>
    </Banner>
