React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

TrialEndingNotifySuccessModal = require './TrialEndingNotifySuccessModal'

storiesOf 'TrialEndingNotifySuccessModal', module
  .add 'default', ->
    <TrialEndingNotifySuccessModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
