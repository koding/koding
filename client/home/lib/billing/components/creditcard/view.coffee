kd = require 'kd'
React = require 'app/react'
ReactDOM = require 'react-dom'
MaskedInput = require 'react-input-mask'
SelectBox = require 'app/components/selectbox'
classnames = require 'classnames'
findScrollableParent = require 'app/util/findScrollableParent'
select = null
lastKnownNode = null


module.exports = class CreditCard extends React.Component

  @propTypes =
    onInputValueChange: React.PropTypes.func.isRequired

  render: ->

    <figure className='HomeAppView--cc'>
      <label>Card Number</label>
      <CardNumber
        hasError={@props.formErrors.get 'number'}
        onChange={@props.onInputValueChange.bind null, 'number'}
        cardType={@props.formValues.get 'cardType'}
        value={@props.formValues.get 'number'}
        isEdited={@props.formValues.get 'isEdited'}
        mask={@props.formValues.get 'mask'} />
      <fieldset className='wrapper--expiration'>
        <label>Expiration</label>
        <Expiration type='month'
          hasError={@props.formErrors.get 'exp_month'}
          onChange={@props.onInputValueChange.bind null, 'expirationMonth'}
          value={@props.formValues.get 'expirationMonth'}
           />
        <Expiration type='year'
          hasError={@props.formErrors.get 'exp_year'}
          onChange={@props.onInputValueChange.bind null, 'expirationYear'}
          value={@props.formValues.get 'expirationYear'} />
      </fieldset>
      <fieldset className='wrapper--cvc'>
        <label>CVC</label>
        <CVC
          hasError={@props.formErrors.get 'cvc'}
          onChange={@props.onInputValueChange.bind null, 'cvc'}
          cardType={@props.formValues.get 'cardType'}
          value={@props.formValues.get 'cvc'} />
      </fieldset>
    </figure>


CardNumber = ({ onChange, hasError, value, cardType, isEdited, mask }) ->

  type = kd.utils.slugify cardType

  placeholder = ''

  unless isEdited
    placeholder = value
    value = ''

  className = "CardNumber-wrapper #{type}"
  className += ' has-error'  if hasError

  <div className={className}>
    <MaskedInput
      mask={mask}
      className={inputClass 'card-number'}
      onChange={pickValue(onChange ? noop)}
      value={value}
      alwaysShowMask={yes}
      placeholder={placeholder} />
  </div>


Expiration = ({ type, onChange, hasError, value }) ->

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

  className = "HomeAppView-selectBoxWrapper expiration-#{type}"
  className += ' has-error'  if hasError

  <div className={className}>
    <SelectBox
      ref={(_select) -> select ?= _select}
      clearable={no}
      onOpen={onOpen}
      onClose={onClose}
      options={options[type]}
      placeholder={placeholders[type]}
      onChange={(e) ->
        delete lastKnownNode.dataset?.innerItemWillScroll
        onChange?(e.value)}
      value={value} />
  </div>

# override onOpen and onClose functions
# we are setting an attribute to element when user open or close the modal
# we can prevent scrolling of parent scrollable view
# so kd will scroll only inner scrollable list when we set `innerItemWillScroll`
onOpen = ->

  node = ReactDOM.findDOMNode select
  node = findScrollableParent node, yes

  if lastKnownNode
    lastKnownNode.dataset.innerItemWillScroll = 'no-scroll'
    return

  return  unless node

  node.dataset.innerItemWillScroll = 'no-scroll'
  lastKnownNode = node


onClose = ->

  node = ReactDOM.findDOMNode select

  node = findScrollableParent node, yes

  if lastKnownNode
    delete lastKnownNode.dataset?.innerItemWillScroll
    return

  return  unless node

  delete node.dataset?.innerItemWillScroll
  lastKnownNode = node


CVC = ({ onChange, hasError, value, cardType }) ->

  mask = switch cardType
    when 'American Express' then '9999'
    else '999'

  className = if hasError then 'has-error' else ''

  <div className={className}>
    <MaskedInput
      mask={mask}
      className={inputClass 'cvc'}
      onChange={pickValue(onChange ? noop)}
      formatChars={{"9": "(\\*|0|1|2|3|4|5|6|7|8|9)"}}
      value={value}
      alwaysShowMask={yes} />
  </div>


pickValue = (onChange) -> (event) -> onChange event.target.value

inputClass = (name) -> ['HomeAppView-input', name].filter(Boolean).join ' '

noop = ->

