module.exports = (el) ->

  { left, right, top, bottom } = el.getBoundingClientRect()

  return \
    top >= 0 and
    left >= 0 and
    bottom <= (global.innerHeight or global.document.documentElement.clientHeight) and
    right <= (global.innerWidth or global.document.documentElement.clientWidth)
