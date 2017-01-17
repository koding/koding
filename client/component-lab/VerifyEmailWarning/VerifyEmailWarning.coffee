kd = require 'kd'
React = require 'react'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'
{ Grid, Row, Col } = require 'react-flexbox-grid'

module.exports = class VerifyEmailWarning extends React.Component

  @propTypes =
    email: React.PropTypes.string
    onClick: React.PropTypes.func

  @defaultProps =
    email: 'xxxxxx@xxxxx.com'
    onClick: kd.noop

  render: ->

    className = kd.utils.curry 'VerifyEmailWarning', @props.className

    <Box type="info">
      <Row>
        <Col xs={12}>
          <Label size="small">
            <strong>Please verify your email address.</strong>
          </Label>
        </Col>
        <Col xs={12}>
          <Label size="small" type="info">
            We sent an email to {@props.email} so that you can click to the link
            in that email to verify your email address. After verification your
            trial will be extended to 30 days. If you didn’t get the email,&nbsp;
            <a href="#" onClick={@props.onClick}>click to resend</a>.
          </Label>
        </Col>
      </Row>
    </Box>
