whoami = require './whoami'

# helper to generate an identifier
# for non-important stuff.

module.exports = (timestamp) ->
  "#{whoami().profile.nickname}-#{timestamp}"
