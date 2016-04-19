shortenUrl = require 'app/util/shortenUrl'

module.exports = generateCollaborationLink = (nickname, channelId, options = {}, callback) ->

  { origin } = global.location

  isAbsolute = options.isAbsolute ? yes

  shortenUrl "#{if isAbsolute then origin else ''}/Collaboration/#{nickname}/#{channelId}", callback
