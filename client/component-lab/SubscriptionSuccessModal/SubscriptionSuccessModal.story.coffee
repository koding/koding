React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

SubscriptionSuccessModal = require './SubscriptionSuccessModal'

storiesOf 'SubscriptionSuccessModal', module
  .add 'default', ->
    <SubscriptionSuccessModal
      isOpen={yes}
      onInviteMembersClick={action 'invite members clicked'} />
