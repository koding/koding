kd = require 'kd'
{ PropTypes, Component } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'
moment = require 'moment'
formatNumber = require 'app/util/formatNumber'
dateDiffInDays = require 'app/util/dateDiffInDays'

Box = require 'lab/Box'
Label = require 'lab/Text/Label'
textStyles = require 'lab/Text/Text.stylus'


module.exports = class SubscriptionHeader extends Component

  renderTitle: ->

    { loading, title } = @props

    title = if loading then 'Loading' else title

    <Col xs={8}>
      <Label size="medium">
        <strong>{title}</strong>
      </Label>
    </Col>


  renderFreeCredit: ->

    { freeCredit } = @props

    <Col xs={4} className={textStyles.right}>
      <Label size="small" type="info">Free Credit: </Label>
      <Label size="small" type="success">${formatNumber freeCredit, 2}</Label>
    </Col>


  renderSubtitle: ->

    { loading, isTrial, endsAt, daysLeft } = @props

    isDanger = no
    subtitle = switch
      when loading
        "Loading subscription info..."

      when isTrial
        isDanger = daysLeft < 4
        "You have #{daysLeft} days left in your trial."

      when endsAt and daysLeft
        billingDate = moment(Number @props.endsAt).format 'MMM Do, YYYY'
        "Your next billing date is #{billingDate}."

      else
        'Enter a credit card to re-activate subscription.'

    <Col xs={8}>
      <Label size="small" type={if isDanger then 'danger' else 'info'}>
        <em>{subtitle}</em>
      </Label>
    </Col>


  renderNextBillingAmount: ->

    { nextBillingAmount, isTrial } = @props

    return null  if isTrial

    <Col xs={4} className={textStyles.right + ' hidden'}>
      <Label size="small" type="info">
        Next Bill Amount: <strong>${formatNumber(nextBillingAmount, 2) or 0}</strong>
      </Label>
    </Col>


  render: ->

    { loading } = @props

    <Row>
      {@renderTitle()}
      {@renderFreeCredit()  unless loading}
      {@renderSubtitle()}
      {@renderNextBillingAmount()  unless loading}
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
