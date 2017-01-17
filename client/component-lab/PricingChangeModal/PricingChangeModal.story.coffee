React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

PricingChangeModal = require './PricingChangeModal'

storiesOf 'PricingChangeModal', module
  .add 'default', ->
    <PricingChangeModal
      isOpen={yes}
      onButtonClick={action 'button clicked'}
      onSecondaryButtonClick={action 'secondary clicked'} />
