React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

TrialEndedMemberModal = require './TrialEndedMemberModal'

storiesOf 'TrialEndedMemberModal', module
  .add 'default', ->
    <TrialEndedMemberModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
