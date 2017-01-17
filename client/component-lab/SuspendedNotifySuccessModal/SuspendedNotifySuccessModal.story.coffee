React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

SuspendedNotifySuccessModal = require './SuspendedNotifySuccessModal'

storiesOf 'SuspendedNotifySuccessModal', module
  .add 'default', ->
    <SuspendedNotifySuccessModal
      isOpen={yes}
      onButtonClick={action 'link clicked'} />
