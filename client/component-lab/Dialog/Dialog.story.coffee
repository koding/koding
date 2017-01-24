React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

Dialog = require './Dialog'

storiesOf 'Dialog', module
  .add 'success', ->
    <Dialog
      type='success'
      isOpen={yes}
      onButtonClick={action 'button clicked'} />

  .add 'danger', ->
    <Dialog
      type='danger'
      isOpen={yes}
      onButtonClick={action 'button clicked'} />
