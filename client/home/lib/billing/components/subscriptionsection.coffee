React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

{ Footer } = DashboardSection = require 'lab/DashboardSection'
Subscription = require 'lab/Subscription'
Button = require 'lab/Button'

module.exports = SubscriptionSection = (props) ->

  <DashboardSection title='Koding Subscription'>
    <Subscription />
    <Footer border>
      <Row style={{margin: '0'}} end='xs'>
        <Col>
          <Button size='small' type='link-secondary'>PRICING DETAILS</Button>
          <Button size='small' type='link-primary-6'>VIEW MEMBERS</Button>
        </Col>
      </Row>
    </Footer>
  </DashboardSection>


