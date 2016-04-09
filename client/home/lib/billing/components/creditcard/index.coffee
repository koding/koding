React = require 'kd-react'


module.exports = class CreditCard extends React.Component

  render: ->
    <figure className='HomeAppView--cc'>
      <label>Card Number</label>
      <input
        className={inputClass 'card-number'}
        placeholder='0000 - 0000 - 0000 - 0000' />
      <fieldset className='wrapper--expiration'>
        <label>Expiration</label>
        <input className={inputClass 'expiration-month'} />
        <input className={inputClass 'expiration-year'} />
      </fieldset>
      <fieldset className='wrapper--cvc'>
        <label>CVC</label>
        <input className={inputClass()} />
      </fieldset>
    </figure>


inputClass = (name) -> ['kdinput', 'text', name].filter(Boolean).join ' '

