React = require 'app/react'

module.exports = class PaymentInformation extends React.Component

  @propTypes =
    onInputValueChange: React.PropTypes.func.isRequired
    onRemoveCard: React.PropTypes.func.isRequired
    onPaymentHistory: React.PropTypes.func.isRequired
    onSave: React.PropTypes.func.isRequired


  sendValue: (type) -> (event) =>
    @props.onInputValueChange type, event.target.value


  pickValue: (type) -> @props.formValues.get type


  pickError: (type) -> @props.formErrors.get type


  render: ->

    <section className='HomeAppView--section billing'>
      <fieldset>
        <label className='HomeAppView-label'>Full Name</label>
        <input
          className={inputClass 'full-name'}
          value={@pickValue 'fullName'}
          onChange={@sendValue 'fullName'}
          placeholder={@props.fullName} />
      </fieldset>
      <fieldset className='email'>
        <label className='HomeAppView-label'>Billing Email Address</label>
        <Email
          value={@pickValue 'email'}
          onChange={@sendValue 'email'}
          userEmail={@props.userEmail} />
      </fieldset>
      <ActionBar
        onRemoveCard={@props.onRemoveCard}
        onPaymentHistory={@props.onPaymentHistory}
        onSave={@props.onSave}
        onCancel={@props.onCancel}
        showCancelButton={@props.formValues.get 'isEdited'} />
    </section>


inputClass = (name) -> ['HomeAppView-input', name].filter(Boolean).join ' '

ActionBar = ({ onRemoveCard, onPaymentHistory, onSave, onCancel, showCancelButton }) ->

  className = 'HomeAppView--button fr hideCancelButton'
  className = 'HomeAppView--button fr showCancelButton'  if showCancelButton


  <fieldset className="HomeAppView--ActionBar">
    <a className="HomeAppView--button" href="#" onClick={onRemoveCard}>
      <span className="title">REMOVE CARD</span>
    </a>
    <a className="HomeAppView--button custom-link-view primary" href="#" onClick={onPaymentHistory}>
      <span className="title">PAYMENT HISTORY</span>
    </a>
    <button className="GenericButton medium fr" href="#" onClick={onSave}>
      <span className="button-title">SAVE</span>
    </button>
    <a className={className} href="#" onClick={onCancel}>
      <span className="title">CANCEL</span>
    </a>
  </fieldset>


Email = ({ value, onChange, userEmail}) ->

  <div>
    <input
      className={inputClass 'email'}
      value={value}
      onChange={onChange}
      placeholder="#{userEmail}" />
  </div>

