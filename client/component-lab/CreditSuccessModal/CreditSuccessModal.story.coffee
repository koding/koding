React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

CreditSuccessModal = require './CreditSuccessModal'

storiesOf 'CreditSuccessModal', module
  .add 'default', ->
    <CreditSuccessModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
