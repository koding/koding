$ = require 'jquery'
findScrollableParent = require 'app/util/findScrollableParent'

###*
 * Scrolls to given DOM element.
 *
 * @param {DOMElement} element
###
module.exports = scrollToElement = (element) ->

  $element = $ element
  $parent = $element.parent()
  $scroller = $ findScrollableParent element

  containerTop = Math.abs $parent.position().top
  elementTop = $element.position().top
  distanceToCenter = (($scroller.height() - $element.height()) / 2)

  scrollTop = containerTop + elementTop - distanceToCenter

  $scroller.animate { scrollTop }, 347
