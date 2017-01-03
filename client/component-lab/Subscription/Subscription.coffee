kd = require 'kd'
{ PropTypes, Component } = React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

SubscriptionHeader = require 'lab/SubscriptionHeader'
SubscriptionNoCardWarning = require 'lab/SubscriptionNoCardWarning'
TrialChargeInfo = require 'lab/TrialChargeInfo'
VerifyEmailWarning = require 'lab/VerifyEmailWarning'
Survey = require 'lab/Survey'

Content = ({ children }) -> <div className={styles.box}>{children}</div>

styles = require './Subscription.stylus'

module.exports = class Subscription extends Component

  renderHeader: ->

    { loading, teamSize, pricePerSeat, daysLeft, hasCreditCard
      isTrial, freeCredit, endsAt, title } = @props

    nextAmount = Number(teamSize) * Number(pricePerSeat)

    <SubscriptionHeader
      hasCreditCard={hasCreditCard}
      loading={loading}
      isTrial={isTrial}
      title={title}
      teamSize={teamSize}
      freeCredit={freeCredit}
      nextBillingAmount={nextAmount}
      daysLeft={daysLeft}
      endsAt={endsAt} />


  renderTrialChargeInfo: ->

    return  unless @props.isTrial

    { daysLeft, endsAt, teamSize, pricePerSeat, onClickInfo } = @props

    <TrialChargeInfo
      daysLeft={daysLeft}
      endsAt={endsAt}
      teamSize={teamSize}
      pricePerSeat={pricePerSeat}
      onClick={onClickInfo} />


  renderExtras: ->

    { isEmailVerified, isSurveyTaken,
      onClickTakeSurvey, email, hasCreditCard } = @props

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
  title: 'Koding Basic Trial (1 Month)'
  teamSize: 1
  freeCredit: 0
  isSurveyTaken: yes
  isEmailVerified: no
  isTrial: no
  onClickTakeSurvey: kd.noop
