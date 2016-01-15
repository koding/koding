$ = require 'jquery'
findScrollableParent = require 'app/util/findScrollableParent'

###*
 * Scrolls to given DOM element.
 *
 * @param {DOMElement} element
###
module.exports = scrollToElement = (element) ->

  $element  = $ element
  $parent   = $element.parent()
  $scroller = $ findScrollableParent element

  scrollableHeight = $scroller.get(0).scrollHeight
  containerTop     = $parent.position().top
  containerHeight  = $parent.height()
  elementTop       = $element.position().top

  heightDelta      = scrollableHeight - containerHeight
  distanceToCenter = (($scroller.height() - $element.height()) / 2)

  scrollTop = heightDelta - containerTop + elementTop - distanceToCenter

  $scroller.animate { scrollTop }, 347

