React = require 'kd-react'

module.exports = class CreditCard extends React.Component

  @propTypes =
    onInputValueChange: React.PropTypes.function.isRequired

  render: ->

    <figure className='HomeAppView--cc'>
      <label>Card Number</label>
      <CardNumber
        onChange={@props.onInputValueChange.bind null, 'number'}
        value={@props.formValues.get 'number'} />
      <fieldset className='wrapper--expiration'>
        <label>Expiration</label>
        <Expiration type='month'
          onChange={@props.onInputValueChange.bind null, 'expirationMonth'}
          value={@props.formValues.get 'expirationMonth'} />
        <Expiration type='year'
          onChange={@props.onInputValueChange.bind null, 'expirationYear'}
          value={@props.formValues.get 'expirationYear'} />
      </fieldset>
      <fieldset className='wrapper--cvc'>
        <label>CVC</label>
        <CVC
          onChange={@props.onInputValueChange.bind null, 'cvc'}
          value={@props.formValues.get 'cvc'} />
      </fieldset>
    </figure>


inputClass = (name) -> ['HomeAppView-input', name].filter(Boolean).join ' '

noop = ->

CardNumber = ({ onChange, value }) ->

  <input
    className={inputClass 'card-number'}
    onChange={onChange ? noop}
    value={value}
    placeholder='0000 - 0000 - 0000 - 0000' />

Expiration = ({ type, onChange, value }) ->

  <input
    className={inputClass "expiration-#{type}"}
    onChange={onChange ? noop}
    value={value} />


CVC = ({ onChange, value }) ->

  <input
    className={inputClass 'cvc'}
    onChange={onChange ? noop}
    value={value} />



