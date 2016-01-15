###*
 * Looks up the DOM until it finds a parent container which has an overflow
 * style that allows for styling. (scroll, auto).
 *
 * @param {DOMElement} element
 * @return {DOMElement} parent - Closest parent element with suitable overflow
 *  styling. If no parent found, `global` (global: window for browser), the
 *  `window` object is returned.
###
module.exports = findScrollableParent = (element) ->

  while element.parentNode
    element = element.parentNode

    # document don't have computed style.
    if element is document
      continue

    if element.classList.contains 'Scrollable'
      return element

    style = global.getComputedStyle element

    overflowY =
      style.getPropertyValue('overflow-y') or
      style.getPropertyValue('overflow')

    if overflowY in ['auto', 'scroll']
      return element

  return global
