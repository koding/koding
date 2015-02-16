isGuest = require './isGuest'

module.exports = ->
  if isGuest() then 'guests' else 'koding'
