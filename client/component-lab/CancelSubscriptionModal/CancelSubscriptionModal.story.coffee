React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

CancelSubscriptionModal = require './CancelSubscriptionModal'

storiesOf 'CancelSubscriptionModal', module
  .add 'default', ->
    <CancelSubscriptionModal
      isOpen={yes}
      onConfirm={action 'on confirm clicked'} />
