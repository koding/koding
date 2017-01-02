React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

{ Footer } = DashboardSection = require 'lab/DashboardSection'
Subscription = require 'lab/Subscription'
Button = require 'lab/Button'

module.exports = class SubscriptionSection extends React.Component

  render: ->

    subscriptionProps = _.omit @props, [
      'onClickPricingDetails', 'onClickViewMembers'
    ]

    { loading, onClickPricingDetails, onClickViewMembers } = @props

    subscriptionProps = { loading: yes }  if loading

    <DashboardSection title='Koding Subscription'>
      <Subscription {...subscriptionProps} />
      <Footer border>
        <Row style={{margin: '0'}} end='xs'>
          <Col>
            <Button
              size='medium'
              type='link-secondary'
              onClick={onClickPricingDetails}>PRICING DETAILS</Button>
            <Button
              size='medium'
              type='link-primary-6'
              onClick={onClickViewMembers}>VIEW MEMBERS</Button>
          </Col>
        </Row>
      </Footer>
    </DashboardSection>
