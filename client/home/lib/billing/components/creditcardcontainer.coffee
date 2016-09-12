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

getUserForAccount = (account, users) ->
  return null  if not (account and users)

  { nickname } = account.profile
  [ userId ] = Object.keys(users).filter (id) ->
    users[id].username is nickname

  return if userId then users[userId] else null


accountUser = createSelector(
  bongo.all('JUser')
  bongo.byId('JAccount', whoami()._id)
  (allUsers, account) -> getUserForAccount account, allUsers
)

userEmail = createSelector(
  accountUser
  (user) -> user?.email
)

nicename = ->
  if acc = whoami()
  then [acc.profile.firstName, acc.profile.lastName].join ' '
  else ''

initialValues = (state) ->
  return  unless userEmail(state)
  return  unless state.creditCard

  email = customer.email(state)

  return creditCard.values(state).set('email', email)


mapStateToProps = (state) ->

  number = if realNumber(state) then formValue(state, 'number') else ''

  props =
    isDirty: isDirty(FORM_NAME)(state)
    formValues:
      number: realNumber and formValue state, 'number'
      name: formValue state, 'name'
      exp_year: formValue state, 'exp_year'
      exp_month: formValue state, 'exp_month'
      email: formValue state, 'email'
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
  onSubmit: addCardToCustomer


CreateCreditCardForm = reduxForm(formOptions)(CreateCreditCardForm)
CreateCreditCardForm = connect(
  mapStateToProps
  null
  null
  { withRef: true }
)(CreateCreditCardForm)

module.exports = CreateCreditCardForm

