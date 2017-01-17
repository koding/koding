{ Brand, NumberPattern, Placeholder, DOT } = require './constants'

upper = (input) -> input.toUpperCase()

# turn slug-case into CONSTANT_CASE
#
# constant('visa') => 'VISA'
# constant('american-express') => 'AMERICAN_EXPRESS'
# constant('american-express', 'NUMBER') => 'NUMBER_AMERICAN_EXPRESS'
constant = (input = '', prefix = '') ->
  input.split('-')
    .concat(if prefix then [prefix] else [])
    .filter(Boolean)
    .map(upper)
    .join('_')


# pattern represents the block length for each card brand.
# default is: [4, 4, 4, 4] for each card brand.
# only exception is american-express: [4, 6, 5]
getNumberPattern = (brand) ->
  NumberPattern[constant brand] ? NumberPattern.DEFAULT


# Returns an array with blocks prefilled with dots.
# It uses number pattern of given brand.
#
# input: '42', 'visa'
# output: ['42••', '••••', '••••', '••••']
#
# input: '34', 'american-express'
# output: ['34••', '••••••', '•••••']
getNumberBlocks = (number, brand) ->
  number = number.replace /\s/g, ''
  pattern = getNumberPattern brand

  index = 0

  pattern.map (blockLength) ->
    slice = number.substr index, blockLength
    index += blockLength

    diff = blockLength - slice.length
    filler = [0...diff].map(-> DOT).join('')
    slice = "#{slice}#{filler}"


# Return placeholder for asked field.
# if there is a custom placeholder defined in [constants]
# it should returns it instead.
#
# [constants]: @see './constants.coffee'
#
# ('number', 'visa') => '•••• •••• •••• ••••'
# ('cvc', 'american-express') => '••••'
getPlaceholder = (field, brand) ->
  # get default field constant
  FIELD = constant field
  BRAND = constant brand

  # get brand specific field constant
  # by suffixing input field constant with
  # brand constant.
  FIELD_BRAND = constant FIELD, BRAND

  return Placeholder[FIELD_BRAND] ? Placeholder[FIELD]


module.exports = {
  getNumberPattern
  getNumberBlocks
  getPlaceholder
}
