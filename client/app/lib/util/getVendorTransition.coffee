module.exports = getVendorTransition = ->

  el = document.createElement('fakeelement')
  transition = null
  transitions =
    transition : 'transitionend'
    OTransition : 'oTransitionEnd'
    MozTransition : 'transitionend'
    WebkitTransition : 'webkitTransitionEnd'
  Object.keys(transitions).forEach (transitionKey) ->
    transition = transitions[transitionKey] unless el.style[transitionKey]
  return transition
