React = require 'react'
Button = require 'lab/Button'
{ Header, Message, Footer, Container } = Banner = require 'lab/Banner'

module.exports = class AddonsBanner extends React.Component

  render: ->

    <Banner
      type="success"
      image="banner_for_billing">
      <Container className="banner">
        <Header
          heading="Boost Your Koding with"
          target="Business Add-On and Support Plans"/>
        <Message>
          Fusce dapibus, tellus ac cursus commodo, tortor mauriscondimentum nibh, ut fermentum massa
        </Message>
        <Footer>
          <a href="/Home/add-ons"><Button type="primary-1" size="medium">EXPLORE</Button></a>
        </Footer>
      </Container>
    </Banner>
