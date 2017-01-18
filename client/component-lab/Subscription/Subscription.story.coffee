React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
moment = require 'moment'

Subscription = require './Subscription'

TRIAL_TITLE = 'Koding Basic Trial (1 Week)'
CUSTOMER_TITLE = '$49.97 per Developer'

NEXT_WEEK = moment(new Date).add(1, 'week').format 'x'
NEXT_MONTH = moment(new Date).add(1, 'month').format 'x'
TWO_DAYS_LATER = moment(new Date).add(2, 'day').format 'x'
TWO_DAYS_EARLIER = moment(new Date).subtract(2, 'day').format 'x'

PRICE_PER_SEAT = 49.97


storiesOf 'Subscription', module
  .add 'default', ->
    <Subscription
      title={CUSTOMER_TITLE}
      pricePerSeat={PRICE_PER_SEAT}
      endsAt={NEXT_MONTH}
      isEmailVerified={yes}
      isSurveyTaken={yes}
      teamSize={5} />

  .add 'with an unconfirmed trial account', ->
    <Subscription
      isTrial={yes}
      title={TRIAL_TITLE}
      isEmailVerified={no}
      email='foo@koding.com'
      isSurveyTaken={no}
      endsAt={NEXT_WEEK} />

  .add 'with a trial account that is not answered the survey', ->
    <Subscription
      isTrial={yes}
      title={TRIAL_TITLE}
      isEmailVerified={yes}
      isSurveyTaken={no}
      email='foo@koding.com'
      endsAt={NEXT_WEEK} />

  .add 'with a fresh/verified trial account', ->
    <Subscription
      isTrial={yes}
      title={TRIAL_TITLE}
      isEmailVerified={yes}
      isSurveyTaken={yes}
      endsAt={NEXT_WEEK} />

  .add 'with almost expiring trial account', ->
    <Subscription
      isTrial={yes}
      title={TRIAL_TITLE}
      isEmailVerified={yes}
      isSurveyTaken={yes}
      endsAt={TWO_DAYS_LATER} />

  .add 'with expired trial account', ->
    <Subscription
      isTrial={yes}
      title={TRIAL_TITLE}
      isEmailVerified={yes}
      isSurveyTaken={yes}
      endsAt={TWO_DAYS_EARLIER} />
