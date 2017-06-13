React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

PastDueAdminModal = require './PastDueAdminModal'

storiesOf 'PastDueAdminModal', module
  .add 'default', ->
    <PastDueAdminModal
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
