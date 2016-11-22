module.exports = getVendorTransition = ->

  el = document.createElement('fakeelement')
  transition = null
  transitions =
    transition : 'transitionend'
    OTransition : 'oTransitionEnd'
    MozTransition : 'transitionend'
    WebkitTransition : 'webkitTransitionEnd'
  _.keys(transitions).forEach (transitionKey) ->
    transition = transitions[transitionKey] if el.style[transitionKey] isnt undefined
  transition
