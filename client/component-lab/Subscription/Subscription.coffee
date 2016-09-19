kd = require 'kd'
{ PropTypes, Component } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

SubscriptionHeader = require 'lab/SubscriptionHeader'
TrialChargeInfo = require 'lab/TrialChargeInfo'
VerifyEmailWarning = require 'lab/VerifyEmailWarning'
Survey = require 'lab/Survey'

Content = ({ children }) -> <div className={styles.box}>{children}</div>

styles = require './Subscription.stylus'

module.exports = class Subscription extends Component

  renderHeader: ->

    { loading, teamSize, pricePerSeat
      isTrial, freeCredit, endsAt, title } = @props

    nextAmount = Number(teamSize) * Number(pricePerSeat)

    <SubscriptionHeader
      loading={loading}
      isTrial={isTrial}
      title={title}
      teamSize={teamSize}
      freeCredit={freeCredit}
      nextBillingAmount={nextAmount}
      endsAt={endsAt} />


  renderTrialChargeInfo: ->

    return  unless @props.isTrial

    <TrialChargeInfo
      endsAt={@props.endsAt}
      teamSize={@props.teamSize}
      pricePerSeat={@props.pricePerSeat}
      onClick={@props.onClickInfo} />


  renderExtras: ->

    { isEmailVerified, isSurveyTaken, onClickTakeSurvey, email } = @props

    if not isEmailVerified
      <VerifyEmailWarning email={email} />
    else if not isSurveyTaken
      <Survey onClick={onClickTakeSurvey} />


  render: ->

    { loading } = @props

    <div>
      <Content>{@renderHeader()}</Content>
      {not loading and <Content>{@renderTrialChargeInfo()}</Content>}
      {not loading and <Content>{@renderExtras()}</Content>}
    </div>


Subscription.propsTypes =
  title: PropTypes.string
  pricePerSeat: PropTypes.number.isRequired
  teamSize: PropTypes.number
  endsAt: PropTypes.number.isRequired
  freeCredit: PropTypes.string
  isSurveyTaken: PropTypes.bool
  isEmailVerified: PropTypes.bool
  isTrial: PropTypes.bool
  onClickTakeSurvey: PropTypes.func


Subscription.defaultProps =
  title: 'Koding Basic Trial (1 Week)'
  teamSize: 1
  freeCredit: 0
  isSurveyTaken: yes
  isEmailVerified: no
  isTrial: no
  onClickTakeSurvey: kd.noop

