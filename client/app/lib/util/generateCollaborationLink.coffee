module.exports = generateCollaborationLink = (nickname, channelId, options = {}) ->

  {origin} = global.location

  isAbsolute = options.isAbsolute ? yes

  return "#{if isAbsolute then origin else ''}/Collaboration/#{nickname}/#{channelId}"


