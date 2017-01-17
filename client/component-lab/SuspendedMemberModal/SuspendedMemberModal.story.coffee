React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

SuspendedMemberModal = require './SuspendedMemberModal'

storiesOf 'SuspendedMemberModal', module
  .add 'default', ->
    <SuspendedMemberModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
