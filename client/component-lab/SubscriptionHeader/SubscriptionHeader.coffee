kd = require 'kd'
{ PropTypes, Component } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'
moment = require 'moment'

dateDiffInDays = require 'app/util/dateDiffInDays'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'
textStyles = require 'lab/Text/Text.stylus'


module.exports = class SubscriptionHeader extends Component

  render: ->
    { title, teamSize, isTrial, endsAt
      nextBillingAmount, freeCredit } = @props

    isDanger = no
    if isTrial
      daysLeft = Math.max 0, dateDiffInDays(new Date(Number endsAt), new Date)
      subtitle = "You have #{daysLeft} days left in your trial."
      isDanger = yes  if daysLeft < 4
    else
      billingDate = moment(Number endsAt).format 'MMM Do, YYYY'
      subtitle = "Your next billing date is #{billingDate}."
      title = "#{title} (#{teamSize} Developers)"

    <Row>

      <Col xs={8}>
        <Label size="medium">
          <strong>{title}</strong>
        </Label>
      </Col>

      <Col xs={4} className={textStyles.right}>
        <Label size="small" type="info">Free Credit: </Label>
        <Label size="small" type="success">${@props.freeCredit}</Label>
      </Col>

      <Col xs={8}>
        <Label size="small" type={if isDanger then 'danger' else 'info'}>
          <em>{subtitle}</em>
        </Label>
      </Col>

      {unless @props.isTrial
        <Col xs={4} className={textStyles.right}>
          <Label size="small" type="info">
            Next Bill Amount: <strong>${nextBillingAmount}</strong>
          </Label>
        </Col>
      }
    </Row>


SubscriptionHeader.propTypes =
  isTrial: PropTypes.bool
  title: PropTypes.string
  freeCredit: PropTypes.number
  nextBillingAmount: PropTypes.number
  endsAt: PropTypes.number


SubscriptionHeader.defaultProps =
  title: 'Koding subscription title'
  freeCredit: 0
  nextBillingAmount: 0
  isTrial: no
  endsAt: Date.now()

