$ = require 'jquery'

module.exports = isScrollThresholdReached = (options) ->

  { el, scrollDirection, isDataLoading, scrollOffset } = options

  $el = $(el)
  scrollHeight = $el.prop('scrollHeight')
  scrollTop    = $el.scrollTop()
  innerHeight  = $el.innerHeight()

  if scrollTop < scrollOffset and scrollDirection is 'up' and isDataLoading is no
    return yes
  return no

