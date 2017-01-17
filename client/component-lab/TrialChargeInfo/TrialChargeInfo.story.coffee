React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
moment = require 'moment'

TrialChargeInfo = require './TrialChargeInfo'

NEXT_MONTH = moment(new Date).add(1, 'month').format 'x'
TWO_DAYS_LATER = moment(new Date).add(2, 'day').format 'x'
TWO_DAYS_EARLIER = moment(new Date).subtract(2, 'day').format 'x'

storiesOf 'TrialChargeInfo', module
  .add 'default', -> <TrialChargeInfo endsAt={NEXT_MONTH} />
  .add 'expiring trial', -> <TrialChargeInfo endsAt={TWO_DAYS_LATER} />
  .add 'expired trial', -><TrialChargeInfo endsAt={TWO_DAYS_EARLIER} />
