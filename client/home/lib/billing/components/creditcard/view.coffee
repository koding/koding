kd = require 'kd'
React = require 'kd-react'
MaskedInput = require 'react-input-mask'
SelectBox = require 'app/components/selectbox'

module.exports = class CreditCard extends React.Component

  @propTypes =
    onInputValueChange: React.PropTypes.func.isRequired

  render: ->

    <figure className='HomeAppView--cc'>
      <label>Card Number</label>
      <CardNumber
        onChange={@props.onInputValueChange.bind null, 'number'}
        cardType={@props.formValues.get 'cardType'}
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
          cardType={@props.formValues.get 'cardType'}
          value={@props.formValues.get 'cvc'} />
      </fieldset>
    </figure>


CardNumber = ({ onChange, value, cardType }) ->

  mask = switch cardType
    when 'American Express' then '9999 999999 99999'
    else '9999 9999 9999 9999'

  type = kd.utils.slugify cardType

  placeholder = ''

  # means that the value is coming from the group card.
  # so we will use this as a placeholder
  if /^\*/.test(value)
    placeholder = value
    value = ''

  <div className="CardNumber-wrapper #{type}">
    <MaskedInput
      mask={mask}
      className={inputClass 'card-number'}
      onChange={pickValue(onChange ? noop)}
      value={value}
      alwaysShowMask={yes}
      placeholder={placeholder} />
  </div>


Expiration = ({ type, onChange, value }) ->

  thisYear = new Date().getFullYear()

  options =
    month: [
      { value: '1', label: 'January' }
      { value: '2', label: 'February' }
      { value: '3', label: 'March' }
      { value: '4', label: 'April' }
      { value: '5', label: 'May' }
      { value: '6', label: 'June' }
      { value: '7', label: 'July' }
      { value: '8', label: 'August' }
      { value: '9', label: 'September' }
      { value: '10', label: 'October' }
      { value: '11', label: 'November' }
      { value: '12', label: 'December' }
    ]
    year: [thisYear..thisYear+20].map (year) -> { value: String(year), label: String(year) }

  placeholders = { month: 'Month', year: 'Year' }

  return \
    <div className={"HomeAppView-selectBoxWrapper expiration-#{type}"}>
      <SelectBox
        clearable={no}
        options={options[type]}
        placeholder={placeholders[type]}
        onChange={(e) -> onChange?(e.value)}
        value={value} />
    </div>


CVC = ({ onChange, value, cardType }) ->

  mask = switch cardType
    when 'American Express' then '9999'
    else '999'

  <MaskedInput
    mask={mask}
    className={inputClass 'cvc'}
    onChange={pickValue(onChange ? noop)}
    formatChars={{"9": "(\\*|0|1|2|3|4|5|6|7|8|9)"}}
    value={value}
    alwaysShowMask={yes} />


pickValue = (onChange) -> (event) -> onChange event.target.value

inputClass = (name) -> ['HomeAppView-input', name].filter(Boolean).join ' '

noop = ->

