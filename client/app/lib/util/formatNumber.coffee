
# formatNumber(number: Number | String, decimalPlaces?: Number) => String | NaN
#
# accepts a number and the amount of numbers after the comma:
#
#   formatNumber(1, 2) === "1.00"
#   formatNumber(21, 5) === "21.00000"
#   formatNumber(2.25, 3) === "2.250"
#
#   # If you omit the decimalPlaces argument 2 will be used.
#   formatNumber(4) === "4.00"
#
#   # It first casts to a Number and then makes a type check.
#   # so that we can use any value that produce a Number after it's being
#   # casted:
#   formatNumber("8.7", 3) === "8.700"
#
#   # it will return `NaN` if it can't cast it into a Number.
#   formatNumber({ a: 1, b:2 }, 3) => NaN
#
module.exports = formatNumber = (number, decimalPlaces = 2) ->

  num = Number number

  if isNumber(num) then num.toFixed(decimalPlaces) else NaN


isNumber = (num) -> not isNaN(Number num)
