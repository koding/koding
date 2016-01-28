$ = require 'jquery'
findScrollableParent = require 'app/util/findScrollableParent'

###*
 * Scrolls to given DOM element.
 * If isCenterPosition is yes, it scrolls to element
 * so that it at the middle of the scrollable area
 * Otherwise:
 * - If element is in visible area, it does nothing.
 * - If element is below visible area, it scrolls so the element
 *   appears at the bottom of visible area.
 * - If element is above visible area, it scrolls so that the element
 *   appears at the top of visible area.
 * If animationDuration is provided, it scrolls with animation (default behavior).
 *
 * @param {DOMElement} element
 * @param {bool} isCenterPosition
 * @param {number} animationDuration
###
module.exports = scrollToElement = (element, isCenterPosition, animationDuration = 347) ->

  container  = findScrollableParent element
  $container = $ container
  $element   = $ element

  containerTop       = container.getBoundingClientRect().top
  containerHeight    = $container.outerHeight no
  containerScrollTop = container.scrollTop
  elementTop         = element.getBoundingClientRect().top
  elementHeight      = $element.outerHeight no
  elementRelTop      = elementTop - containerTop + containerScrollTop

  if isCenterPosition

    distanceToCenter = if containerHeight > elementHeight
    then (containerHeight - elementHeight) / 2
    else 0
    scrollTop = elementRelTop - distanceToCenter

  else

    # element is in visible area
    if elementTop - containerTop + elementHeight < containerHeight and elementTop - containerTop >= 0
      return

    # element is above visible area
    else if elementTop - containerTop < 0
      scrollTop = elementRelTop

    # element is below visible area
    else if elementTop - containerTop + elementHeight > containerHeight
      scrollTop = elementRelTop - containerHeight + elementHeight

  if animationDuration
    $container.animate { scrollTop }, animationDuration
  else
    container.scrollTop = scrollTop
