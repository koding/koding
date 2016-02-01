$ = require 'jquery'
findScrollableParent = require 'app/util/findScrollableParent'

module.exports = getScrollablePosition = (element) ->

  container  = findScrollableParent element
  $container = $ container
  $element   = $ element

  containerTop       = container.getBoundingClientRect().top
  containerHeight    = $container.outerHeight no
  containerScrollTop = container.scrollTop
  elementTop         = element.getBoundingClientRect().top
  elementHeight      = $element.outerHeight no

  top = elementTop - containerTop + containerScrollTop

  if elementTop - containerTop + elementHeight <= containerHeight and elementTop - containerTop >= 0
    return { top, visible : yes }

  if elementTop - containerTop < 0
    return { top, visible : no, relativePosition : 'above' }

  if elementTop - containerTop + elementHeight > containerHeight
    return { top, visible : no, relativePosition : 'below' }

  return { top, visible : no }  