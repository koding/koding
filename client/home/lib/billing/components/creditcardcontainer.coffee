{ reduxForm, SubmissionError, reset: resetForm } = require 'redux-form'
{ connect } = require 'react-redux'

{ updateCard } = require 'app/redux/modules/payment'

CreateCreditCardForm = require 'lab/CreateCreditCardForm'

{ select, FORM_NAME, mapErrors } = require './helpers'


# handleSubmit: redux-form `onSubmit` handler for credit card form.
# it handles errors in a way that redux-form can make sense.
#
# @param {object} values - form values
# @param {function} dispatch - Redux dispatch function
# @return {Promise}
handleSubmit = (values, dispatch) ->

  Promise.resolve()
    .then -> dispatch(updateCard values)
    .then -> dispatch(resetForm FORM_NAME)
    .catch (errors) ->
      console.error 'errors in card submission', errors
      throw new SubmissionError mapErrors errors


# first we connect reduxForm to ensure
# form values are stored in store and onSubmit is
# called when submit event is fired.
CreateCreditCardForm = reduxForm(
  form: FORM_NAME
  enableReinitialize: yes
  onSubmit: handleSubmit
)(CreateCreditCardForm)


mapStateToProps = (state) ->
  return {
    isDirty: select.dirty(state)
    # if form is not dirty credit card figure will use this data
    # tho show existing credit card.
    placeholders: select.placeholders(state)
    # if form is dirty, credit card figure will use this data to show
    # a preview for the card user is entering.
    formValues: select.values(state)
  }


# then we connect our own state mapper to implement our custom logic.
CreateCreditCardForm = connect(
  mapStateToProps
  null
  null
  { withRef: true }
)(CreateCreditCardForm)

module.exports = CreateCreditCardForm
