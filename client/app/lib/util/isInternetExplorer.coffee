module.exports = ->

  { userAgent } = global.navigator

  msie    = userAgent.indexOf('MSIE ') > 0
  trident = userAgent.indexOf('Trident/') > 0
  edge    = userAgent.indexOf('Edge/') > 0;

  return msie or trident or edge
