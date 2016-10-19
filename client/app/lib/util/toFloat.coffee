
# toFloat(number: Number | String, decimalPlaces?: Number) => String | NaN
#
# accepts a number and the amount of numbers after the comma:
#
#   toFloat(1, 2) === "1.00"
#   toFloat(21, 5) === "21.00000"
#   toFloat(2.25, 3) === "2.250"
#
#   # If you omit the decimalPlaces argument 2 will be used.
#   toFloat(4) === "4.00"
#
#   # It first casts to a Number and then makes a type check.
#   # so that we can use any value that produce a Number after it's being
#   # casted:
#   toFloat("8.7", 3) === "8.700"
#
#   # it will return `NaN` if it can't cast it into a Number.
#   toFloat({ a: 1, b:2 }, 3) => NaN
#
module.exports = toFloat = (number, decimalPlaces = 2) ->

  num = Number number

  if isNumber(num) then num.toFixed(decimalPlaces) else NaN


isNumber = (num) -> not isNaN(Number num)
