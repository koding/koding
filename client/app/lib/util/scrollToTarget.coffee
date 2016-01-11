$ = require 'jquery'

###*
 * Util function to scroll container element to specific target within it.
 * Usually it is used to scroll the list to its specific item.
 * It works correctly, if container elements are wrapped with relatively
 * positioned element. In this case browser calculates target position
 * withing container correctly.
 * Scrolling rules are:
 * - If target is in visible area of container, it does nothing.
 * - If target is below visible area, it scrolls so the target
 *   appears at the bottom of visible area.
 * - If target is above visible area or it is below visible area but
 *   doesn't fit container's height, it scrolls so the target
 *   appears at the top of visible area.
 *
 * @param {DOMElement} container
 * @param {DOMElement} target
###
module.exports = (container, target) ->

  container = $ container
  target    = $ target

  containerScrollTop    = container.scrollTop()
  containerHeight       = container.height()
  containerScrollBottom = containerScrollTop + containerHeight

  targetPosition        = target.position()
  return  unless targetPosition

  targetTop             = targetPosition.top + containerScrollTop
  targetHeight          = target.outerHeight yes
  targetBottom          = targetTop + targetHeight

  isBelowVisibleArea    = targetBottom > containerScrollBottom
  isAboveVisibleArea    = targetTop < containerScrollTop
  fitContainerHeight    = targetHeight < containerHeight

  if isBelowVisibleArea and fitContainerHeight
    hasNextSibling = target.next().length > 0

    scrollTop = if hasNextSibling
    then targetBottom - containerHeight
    else container.get(0).scrollHeight

    container.scrollTop scrollTop
  else if isAboveVisibleArea or (isAboveVisibleArea and not fitContainerHeight)
    hasPrevSibling = target.prev().length > 0
    scrollTop = if hasPrevSibling then targetTop else 0
    container.scrollTop scrollTop
