React = require 'react'
moment = require 'moment'
{ storiesOf, action } = require '@kadira/storybook'

SubscriptionHeader = require './SubscriptionHeader'

TRIAL_TITLE = 'Koding Basic Trial (1 Week)'
NEXT_WEEK = moment(new Date).add(1, 'week').format 'x'
NEXT_MONTH = moment(new Date).add(1, 'month').format 'x'
TWO_DAYS_LATER = moment(new Date).add(2, 'day').format 'x'
TWO_DAYS_EARLIER = moment(new Date).subtract(2, 'day').format 'x'

storiesOf 'SubscriptionHeader', module
  .add 'default', ->
    <SubscriptionHeader endsAt={NEXT_MONTH} />

  .add 'with a fresh trial account', ->
    <SubscriptionHeader
      isTrial={yes}
      title={TRIAL_TITLE}
      endsAt={NEXT_WEEK} />

  .add 'with almost expiring trial account', ->
    <SubscriptionHeader
      isTrial={yes}
      title={TRIAL_TITLE}
      endsAt={TWO_DAYS_LATER} />

  .add 'with expired trial account', ->
    <SubscriptionHeader
      isTrial={yes}
      title={TRIAL_TITLE}
      endsAt={TWO_DAYS_EARLIER} />
