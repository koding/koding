React = require 'kd-react'

module.exports = class PaymentInformation extends React.Component

  @propTypes =
    onInputValueChange: React.PropTypes.func.isRequired
    onRemoveCard: React.PropTypes.func.isRequired
    onPaymentHistory: React.PropTypes.func.isRequired
    onSave: React.PropTypes.func.isRequired


  sendValue: (type) -> (event) =>
    @props.onInputValueChange type, event.target.value


  pickValue: (type) -> @props.formValues.get type


  render: ->

    <section className='HomeAppView--section billing'>
      <fieldset>
        <label>Full Name:</label>
        <input
          className={inputClass 'full-name'}
          value={@pickValue 'fullName'}
          onChange={@sendValue 'fullName'}
          placeholder='Enter your name and surname' />
      </fieldset>
      <fieldset className='email'>
        <label>E-mail Address:</label>
        <input
          className={inputClass 'email'}
          value={@pickValue 'email'}
          onChange={@sendValue 'email'}
          placeholder='Enter your e-mail' />
      </fieldset>
      <ActionBar
        onRemoveCard={@props.onRemoveCard}
        onPaymentHistory={@props.onPaymentHistory}
        onSave={@props.onSave} />
    </section>


inputClass = (name) -> ['HomeAppView-input', 'HomeAppView-input--cc-form', name].filter(Boolean).join ' '

ActionBar = ({ onRemoveCard, onPaymentHistory, onSave }) ->

  <fieldset className="HomeAppView--ActionBar">
    <a className="HomeAppView--button" href="#" onClick={onRemoveCard}>
      <span className="title">REMOVE CARD</span>
    </a>
    <a className="HomeAppView--button custom-link-view primary" href="#" onClick={onPaymentHistory}>
      <span className="title">PAYMENT HISTORY</span>
    </a>
    <a className="HomeAppView--button custom-link-view primary fr" href="#" onClick={onSave}>
      <span className="title">SAVE</span>
    </a>
  </fieldset>

