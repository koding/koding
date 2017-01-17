React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

VerifyEmailModal = require './VerifyEmailModal'

storiesOf 'VerifyEmailModal', module
  .add 'default', ->
    <VerifyEmailModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
