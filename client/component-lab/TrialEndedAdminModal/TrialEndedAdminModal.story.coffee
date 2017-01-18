React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

TrialEndedAdminModal = require './TrialEndedAdminModal'

storiesOf 'TrialEndedAdminModal', module
  .add 'default', ->
    <TrialEndedAdminModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
