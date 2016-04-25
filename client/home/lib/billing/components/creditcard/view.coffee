React = require 'kd-react'
MaskedInput = require 'react-maskedinput'

module.exports = class CreditCard extends React.Component

  @propTypes =
    onInputValueChange: React.PropTypes.func.isRequired

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


CardNumber = ({ onChange, value }) ->

  <MaskedInput
    mask="1111 1111 1111 1111"
    className={inputClass 'card-number'}
    onChange={pickValue(onChange ? noop)}
    value={value}
    placeholder='0000 0000 0000 0000' />

Expiration = ({ type, onChange, value }) ->

  <input
    className={inputClass "expiration-#{type}"}
    onChange={pickValue(onChange ? noop)}
    value={value} />


CVC = ({ onChange, value }) ->

  <MaskedInput
    mask="111"
    className={inputClass 'cvc'}
    onChange={pickValue(onChange ? noop)}
    value={value}
    placeholder='000' />


pickValue = (onChange) -> (event) -> onChange event.target.value

inputClass = (name) -> ['HomeAppView-input', name].filter(Boolean).join ' '

noop = ->

