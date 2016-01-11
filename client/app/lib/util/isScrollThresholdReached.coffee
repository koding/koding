$ = require 'jquery'

module.exports = isScrollThresholdReached = (options) ->

  { el, scrollDirection, isDataLoading, scrollOffset, scrollMoveTo } = options

  $el = $(el)
  scrollHeight = $el.prop('scrollHeight')
  scrollTop    = $el.scrollTop()
  innerHeight  = $el.innerHeight()

  return no  if isDataLoading

  if scrollDirection is 'up' and scrollMoveTo is 'up' and scrollTop < scrollOffset
    return yes
  else if scrollDirection is 'down' and scrollMoveTo is 'down' and (scrollOffset > scrollHeight - scrollTop - innerHeight)
    return yes

  return no
