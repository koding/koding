module.exports = ->

  { userAgent } = global.navigator

  return /^((?!chrome|android).)*safari/i.test userAgent