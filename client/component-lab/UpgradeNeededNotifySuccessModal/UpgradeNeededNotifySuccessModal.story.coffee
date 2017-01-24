React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

UpgradeNeededNotifySuccessModal = require './UpgradeNeededNotifySuccessModal'

storiesOf 'UpgradeNeededNotifySuccessModal', module
  .add 'default', ->
    <UpgradeNeededNotifySuccessModal
      isOpen={yes}
      onButtonClick={action 'link clicked'} />
