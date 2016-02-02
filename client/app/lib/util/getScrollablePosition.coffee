$ = require 'jquery'
findScrollableParent = require 'app/util/findScrollableParent'

###*
 * Get element position in scrollable container
 * in relation to visible portion of scrollable area.
 * Return value can be:
 * - 'inside' (element is in visible area)
 * - 'above' (element is above visible area)
 * - 'below' (element is below visible area)
 *
 * @param {DOMElement} element
 * @return {string}
###
module.exports = getScrollablePosition = (element) ->

  container  = findScrollableParent element
  $container = $ container
  $element   = $ element

  containerTop       = container.getBoundingClientRect().top
  containerHeight    = $container.outerHeight no
  containerScrollTop = container.scrollTop
  elementTop         = element.getBoundingClientRect().top
  elementHeight      = $element.outerHeight no

  if elementTop - containerTop + elementHeight <= containerHeight and elementTop - containerTop >= 0
    return 'inside'

  if elementTop - containerTop < 0
    return 'above'

  if elementTop - containerTop + elementHeight > containerHeight
    return 'below'
