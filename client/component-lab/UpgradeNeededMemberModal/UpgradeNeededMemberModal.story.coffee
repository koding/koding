React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

UpgradeNeededMemberModal = require './UpgradeNeededMemberModal'

storiesOf 'UpgradeNeededMemberModal', module
  .add 'default', ->
    <UpgradeNeededMemberModal
      isOpen={yes}
      onButtonClick={action 'button clicked'}
      onSecondaryButtonClick={action 'secondary clicked'} />



