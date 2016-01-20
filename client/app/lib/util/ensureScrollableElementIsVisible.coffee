$ = require 'jquery'
findScrollableParent = require 'app/util/findScrollableParent'

###*
 * Util function to ensure that element is visible within its scrollable container.
 * Usually it is used to scroll the list to its specific item.
 * It works correctly, if container elements are wrapped with relatively
 * positioned element. In this case browser calculates element position
 * withing container correctly.
 * Scrolling rules are:
 * - If element is in visible area of container, it does nothing.
 * - If element is below visible area, it scrolls so the element
 *   appears at the bottom of visible area.
 * - If element is above visible area or it is below visible area but
 *   doesn't fit container's height, it scrolls so the element
 *   appears at the top of visible area.
 *
 * @param {DOMElement} element
###
module.exports = ensureScrollableElementIsVisible = (element) ->

  container = $ findScrollableParent element
  element   = $ element

  containerScrollTop    = container.scrollTop()
  containerHeight       = container.height()
  containerScrollBottom = containerScrollTop + containerHeight

  elementPosition       = element.position()
  return  unless elementPosition

  elementTop            = elementPosition.top + containerScrollTop
  elementHeight         = element.outerHeight yes
  elementBottom         = elementTop + elementHeight

  isBelowVisibleArea    = elementBottom > containerScrollBottom
  isAboveVisibleArea    = elementTop < containerScrollTop
  fitContainerHeight    = elementHeight < containerHeight

  if isBelowVisibleArea and fitContainerHeight
    hasNextSibling = element.next().length > 0

    scrollTop = if hasNextSibling
    then elementBottom - containerHeight
    else container.get(0).scrollHeight

    container.scrollTop scrollTop
  else if isAboveVisibleArea or (isAboveVisibleArea and not fitContainerHeight)
    hasPrevSibling = element.prev().length > 0
    scrollTop = if hasPrevSibling then elementTop else 0
    container.scrollTop scrollTop
