React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

SubscriptionNoCardWarning = require './SubscriptionNoCardWarning'

storiesOf 'SubscriptionNoCardWarning', module
  .add 'default', -> <SubscriptionNoCardWarning />
