kd = require 'kd'
React = require 'react'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'
{ Grid, Row, Col } = require 'react-flexbox-grid'

module.exports = class SubscriptionNoCardWarning extends React.Component

  render: ->

    className = kd.utils.curry 'SubscriptionNoCardWarning', @props.className

    <Box type="danger" border={1}>
      <Row>
        <Col xs={12}>
          <Label type="danger" size="small">
            <strong>Please enter a credit card.</strong>
          </Label>
        </Col>
        <Col xs={12}>
          <Label size="small" type="info">
            We hope you have enjoyed using Koding. Please enter a credit card
            to continue.
          </Label>
        </Col>
      </Row>
    </Box>
