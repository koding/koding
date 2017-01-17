
module.exports = dateDiffInDays = (a, b) ->

  MILLISECONDS_PER_DAY = 1000 * 60 * 60 * 24

  a = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate())
  b = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate())

  return Math.floor((a - b) / MILLISECONDS_PER_DAY)
