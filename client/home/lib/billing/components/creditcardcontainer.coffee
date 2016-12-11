_ = require 'lodash'
{ reduxForm, SubmissionError, isDirty, reset: resetForm } = require 'redux-form'
{ connect } = require 'react-redux'

stripe = require 'app/redux/modules/stripe'
customer = require 'app/redux/modules/payment/customer'

CreateCreditCardForm = require 'lab/CreateCreditCardForm'

{ select, FORM_NAME, mapErrors } = require './helpers'





# first we connect reduxForm to ensure
# form values are stored in store and onSubmit is
# called when submit event is fired.
CreateCreditCardForm = reduxForm(
  form: FORM_NAME
  enableReinitialize: yes
)(CreateCreditCardForm)

mapStateToProps = (state, props) ->
  return {
    isDirty: select.dirty(state)
    # if form is not dirty credit card figure will use this data
    # tho show existing credit card.
    placeholders: select.placeholders(state)
    # if form is dirty, credit card figure will use this data to show
    # a preview for the card user is entering.
    formValues: select.values(state)
  }


# then we connect our own state mapper.
# make sure that necessary state values are passed
# down to the form.
CreateCreditCardForm = connect(
  mapStateToProps
  null
  null
  { withRef: true }
)(CreateCreditCardForm)

module.exports = CreateCreditCardForm

