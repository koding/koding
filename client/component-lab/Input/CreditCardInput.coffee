{ PropTypes } = React = require 'react'
{ Field } = require 'redux-form'

Input = require './Input'

{ Brand } = require 'lab/CreditCard/constants'
{ getPlaceholder } = require 'lab/CreditCard/helpers'

module.exports = CreditCardInput = (props) ->

  { brand, fieldType, placeholder } = props

  mask = makeMask fieldType, brand
  placeholder or= getPlaceholder fieldType, brand

  props = _.omit props, ['brand', 'fieldType']

  <Input
    mask={mask}
    placeholder={placeholder}
    placeholderChar='•'
    {...props} />


CreditCardInput.Field = (props) ->
  <Field {...props} component={InputForField} />


InputForField = (props) ->
  { input, meta: { error } } = props

  props = _.assign(
    # remove special props from props. This will result in the real props we
    # passed to the `Input.Field` component.
    _.omit(props, ['input', 'meta', 'error'])
    # merge it with input props.
    input
  )

  <CreditCardInput {...props} error={error} />


CreditCardInput.propTypes =
  brand: PropTypes.oneOf [
    Brand.JCB
    Brand.MAESTRO
    Brand.MASTER_CARD
    Brand.MASTERCARD
    Brand.AMERICAN_EXPRESS
    Brand.DINERS_CLUB
    Brand.DISCOVER
    Brand.VISA
    Brand.DEFAULT
  ]


CreditCardInput.defaultProps =
  brand: Brand.DEFAULT


templates =
  number:
    amex: ['••••', '••••••', '•••••']
    other: ['••••', '••••', '••••', '••••']

  cvc:
    amex: ['••••']
    other: ['•••']


getCardBrand = (number) ->
  number = number.replace /\D/g, ''
  require('card-validator').number(number).card?.type


makeCardProps = (type, brand) ->
  return {
    mask: makeMask type, brand
    placeholder: makePlaceholder type, brand
  }


normalizeBrand = (brand) -> if brand is 'american-express' then 'amex' else 'other'


makeMask = (type, brand) -> (value) ->

  brand = getCardBrand value  if type is 'number'

  template = templates[type][normalizeBrand brand]

  mask = template
    .map (group) -> group.split('').map (char) -> /\d/
    .reduce (res, group, index) ->
      res = res.concat group
      if index is template.length - 1 then res else res.concat [' ']
    , []

  return mask


makePlaceholder = (type, brand) -> templates[type][normalizeBrand brand].join ' '
