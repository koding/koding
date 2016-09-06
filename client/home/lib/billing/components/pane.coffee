React = require 'react'

SubscriptionSection = require './subscriptionsection'
PaymentSection = require './paymentsectioncontainer'


module.exports = BillingPane = (props) ->

  { subscriptionTitle, pricePerSeat, teamSize,
    endsAt, freeCredit, isSurveyTaken, isEmailVerified, isTrial
    onClickTakeSurvey, onClickPricingDetails, onClickViewMembers } = props

  <div>
    <SubscriptionSection
      subscriptionTitle={subscriptionTitle}
      pricePerSeat={pricePerSeat}
      teamSize={teamSize}
      endsAt={endsAt}
      freeCredit={freeCredit}
      isSurveyTaken={isSurveyTaken}
      isEmailVerified={isEmailVerified}
      isTrial={isTrial}
      onClickTakeSurvey={onClickTakeSurvey}
      onClickPricingDetails={onClickPricingDetails}
      onClickViewMembers={onClickViewMembers} />
    <PaymentSection />
  </div>


BillingPane.defaultProps =
  onClickViewMembers: ->

