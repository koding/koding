kd = require 'kd'
React = require 'react'
SubscriptionHeader = require 'lab/SubscriptionHeader'
ChargeInfo = require 'lab/ChargeInfo'
VerifyEmailWarning = require 'lab/VerifyEmailWarning'
Survey = require 'lab/Survey'

TrialExpireWarning = require 'lab/TrialExpireWarning'

module.exports = class Subscription extends React.Component

  @propsTypes =
    subscriptionTitle: React.PropTypes.string
    pricePerSeat: React.PropTypes.string
    teamSize: React.PropTypes.string
    trialEndsAt: React.PropTypes.string
    endsAt: React.PropTypes.string
    freeCredit: React.PropTypes.string
    nextBillingAmount: React.PropTypes.string
    creditAmount: React.PropTypes.string
    isExpired: React.PropTypes.bool
    isSurveyTaken: React.PropTypes.bool
    isEmailVerified: React.PropTypes.bool
    isTrial: React.PropTypes.bool
    onClickPricingDetail: React.PropTypes.func
    onClickViewMembers: React.PropTypes.func
    onClickInfo: React.PropTypes.func
    onClickTakeSurvey: React.PropTypes.func
    onClickResendEmail: React.PropTypes.func


  @defaultProps =

    subscriptionTitle: 'Koding Basic Trial (1 Week)'
    pricePerSeat: '49.97'
    teamSize: '4'
    trialEndsAt: 'You have 6 days left'
    endsAt: 'Sep 28, 2016'
    freeCredit: '100.00'
    nextBillingAmount: '99.88'
    isExpired: no
    isSurveyTaken: no
    isEmailVerified: no
    isTrial: no
    onClickPricingDetail: kd.noop
    onClickViewMembers: kd.noop
    onClickInfo: kd.noop
    onClickTakeSurvey: kd.noop
    onClickResendEmail: kd.noop


  renderHeader: ->

    title = "#{@props.pricePerSeat} per Developer (#{@props.teamSize} Developers)"
    subtitle = "Your next billing date is #{@props.endsAt}."

    if @props.isTrial
      title = @props.subscriptionTitle
      subtitle = "You have #{@props.trialEndsAt} days left." #plural singular

    <SubscriptionHeader
      danger={@props.isExpired}
      title={title}
      subtitle={subtitle}
      freeCredit={@props.freeCredit}
      nextBillingAmount={@props.nextBillingAmount} />


  renderChargeInfo: ->

    return  if @props.isExpired

    <ChargeInfo
      teamSize={@props.teamSize}
      pricePerSeat={@props.pricePerSeat}
      onClick={@props.onClickInfo} />


  renderVerifyEmailWarning: ->

    return  if @props.isExpired
    return  unless @props.isEmailVerified

    <VerifyEmailWarning />


  renderSurvey: ->

    return  if @props.isExpired
    return  if @props.isSurveyTaken

    <Survey onClick={@props.onClickTakeSurvey} />


  renderTrialExpireWarning: ->

    return  unless @props.isExpired

    <TrialExpireWarning
      teamSize={@props.teamSize}
      pricePerSeat={@props.pricePerSeat} />


  renderButtons: ->

    className = 'HomeAppView Subscription--footer'
    if @props.isEmailVerified and @props.isSurveyTaken
      className = "#{className} with-border"

    <div className={className}>
      <button onClick={@props.onClickPricingDetail}>PRICING DETAILS</button>
      <button onClick={@props.onClickViewMembers}>VIEW MEMBERS</button>
    </div>


  render: ->

    <div className='Subscription'>
      {@renderHeader()}
      {@renderChargeInfo()}
      {@renderSurvey()}
      {@renderVerifyEmailWarning()}
      {@renderTrialExpireWarning()}
      {@renderButtons()}
    </div>


