module.exports = (el, container) ->
  while el
    return yes  if el is container
    el = el.parentNode
  no


