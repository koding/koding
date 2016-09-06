{ reduxForm, formValueSelector, SubmissionError } = require 'redux-form'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'
validator = require 'card-validator'

{ CREATE_TOKEN } = stripe = require 'app/redux/modules/stripe'

CreateCreditCardForm = require 'lab/CreateCreditCardForm'

FORM_NAME = 'create-credit-card'
formValue = formValueSelector(FORM_NAME)

realNumber = (state) -> formValue(state, 'number')?.replace /\D/g, ''

cardBrand = createSelector(
  realNumber
  (number) -> number and validator.number(number).card?.type
)

mapStateToProps = (state) ->
  return {
    values:
      number: formValue state, 'number'
      name: formValue state, 'name'
      exp_year: formValue state, 'exp_year'
      exp_month: formValue state, 'exp_month'
      brand: cardBrand state
      realNumber: realNumber state
  }

mapErrorsToValues = (errors) ->
  errors.reduce (res, { error }) ->
    res[error.param] = error.message
    return res
  , {}


formOptions =
  form: FORM_NAME
  onSubmit: (values, dispatch) ->
    dispatch(stripe.createToken values)
      .catch (errors) -> throw new SubmissionError mapErrorsToValues errors


CreateCreditCardForm = connect(mapStateToProps)(CreateCreditCardForm)
CreateCreditCardForm = reduxForm(formOptions)(CreateCreditCardForm)

module.exports = CreateCreditCardForm

