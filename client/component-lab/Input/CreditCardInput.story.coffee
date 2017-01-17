React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

CreditCardInput = require './CreditCardInput'


storiesOf 'CreditCardInput', module
  .add 'regular card (visa/master/discover/etc.)', ->
    <CreditCardInput brand='visa' onChange={onChange} />

  .add 'amex card', ->
    <CreditCardInput
      title='Credit Card Number' brand='american-express' />

onChange = (e) -> action 'onChange', e.target.value
