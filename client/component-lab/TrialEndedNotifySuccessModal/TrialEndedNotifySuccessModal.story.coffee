React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

TrialEndedNotifySuccessModal = require './TrialEndedNotifySuccessModal'

storiesOf 'TrialEndedNotifySuccessModal', module
  .add 'default', ->
    <TrialEndedNotifySuccessModal
      isOpen={yes}
      onButtonClick={action 'link clicked'} />
