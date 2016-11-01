_ = require 'lodash'
{ reduxForm, formValueSelector, SubmissionError, isDirty } = require 'redux-form'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'
validator = require 'card-validator'
whoami = require 'app/util/whoami'

stripe = require 'app/redux/modules/stripe'
bongo = require 'app/redux/modules/bongo'
customer = require 'app/redux/modules/payment/customer'
creditCard = require 'app/redux/modules/payment/creditcard'

CreateCreditCardForm = require 'lab/CreateCreditCardForm'

FORM_NAME = 'create-credit-card'
formValue = formValueSelector(FORM_NAME)

realNumber = (state) -> formValue(state, 'number')?.replace /\D/g, ''

slugify = (word) -> if word then word.split(' ').join '-' else ''

cardBrand = createSelector(
  realNumber
  (number) ->
    brand = if number then validator.number(number).card?.type else ''

    return slugify brand
)

initialValues = (state) ->
  return  unless state.customer
  return creditCard.values(state)


mapStateToProps = (state) ->

  number = if realNumber(state) then formValue(state, 'number') else ''

  props =
    isDirty: isDirty(FORM_NAME)(state)
    formValues:
      number: number
      exp_year: formValue state, 'exp_year'
      exp_month: formValue state, 'exp_month'
      brand: cardBrand state
      realNumber: realNumber(state)

  # first time we passed down an initialValues prop to the redux form it will
  # use that as **real** initialValues, and after that if you pass down a
  # different initialValues prop, it will use the values and it will mark the
  # form dirty. But since the initial loads trigger state updates, and email is
  # being loaded after form is initialized, it causes problems.
  if initials = initialValues(state)
    props.initialValues = initials

  return props


mapErrorsToValues = (errors) ->
  errors.reduce (res, { error }) ->
    res[error.param] = error.message
    return res
  , {}


addCardToCustomer = (values, dispatch) ->

  dispatch(stripe.createToken values)
    .then (token) -> dispatch(customer.update { source: { token } })
    .catch (errors) -> throw new SubmissionError mapErrorsToValues errors


formOptions =
  form: FORM_NAME
  enableReinitialize: yes
  onSubmit: addCardToCustomer


CreateCreditCardForm = reduxForm(formOptions)(CreateCreditCardForm)
CreateCreditCardForm = connect(
  mapStateToProps
  null
  null
  { withRef: true }
)(CreateCreditCardForm)

module.exports = CreateCreditCardForm

