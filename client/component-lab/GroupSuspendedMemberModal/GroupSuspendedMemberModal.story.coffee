React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

GroupSuspendedMemberModal = require './GroupSuspendedMemberModal'

storiesOf 'GroupSuspendedMemberModal', module
  .add 'default', ->
    <GroupSuspendedMemberModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />


