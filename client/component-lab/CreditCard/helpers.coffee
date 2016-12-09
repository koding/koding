{ Brand, NumberPattern, Placeholder, DOT } = require './constants'

upper = (input) -> input.toUpperCase()

# input: 'visa' => output: 'VISA'
# input: 'american-express' => output: 'AMERICAN_EXPRESS'
constant = (brand) -> brand.split('-').map(upper).join('_')

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


module.exports = {
  getNumberBlocks
}

