kd = require 'kd'
{ PropTypes, Component } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'
moment = require 'moment'

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
      <Label size="small" type="success">${freeCredit}</Label>
    </Col>


  renderSubtitle: ->

    { loading, isTrial, endsAt } = @props

    isDanger = no
    subtitle = switch
      when loading
        "Loading subscription info..."

      when isTrial
        daysLeft = Math.max 0, dateDiffInDays(new Date(Number endsAt), new Date)
        isDanger = daysLeft < 4
        "You have #{daysLeft} days left in your trial."

      else
        billingDate = moment(Number @props.endsAt).format 'MMM Do, YYYY'
        "Your next billing date is #{billingDate}."

    <Col xs={8}>
      <Label size="small" type={if isDanger then 'danger' else 'info'}>
        <em>{subtitle}</em>
      </Label>
    </Col>


  renderNextBillingAmount: ->

    return  if @props.isTrial

    { nextBillingAmount } = @props

    <Col xs={4} className={textStyles.right}>
      <Label size="small" type="info">
        Next Bill Amount: <strong>${nextBillingAmount or 0}</strong>
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

