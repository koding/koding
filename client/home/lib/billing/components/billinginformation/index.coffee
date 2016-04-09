React = require 'kd-react'

module.exports = class BillingInformation extends React.Component

  render: ->

    <section className='HomeAppView--section billing'>
      <fieldset>
        <label>Full Name:</label>
        <input className={inputClass 'full-name'} />
      </fieldset>
      <fieldset className='address'>
        <label>Address:</label>
        <input className={inputClass 'address'} />
        <input className={inputClass 'unit'} />
      </fieldset>
      <fieldset className='zipCode'>
        <label>Zip Code:</label>
        <input className={inputClass 'zip'} />
        <input className={inputClass 'city'} />
        <input className={inputClass 'state'} />
      </fieldset>
      <fieldset className='phone'>
        <label>Phone number:</label>
        <input className={inputClass 'phone'} />
      </fieldset>
    </section>


inputClass = (name) -> ['kdinput', 'text', name].filter(Boolean).join ' '
