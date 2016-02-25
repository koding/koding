module.exports = generateCollaborationLink = (nickname, channelId, { isAbsolute = yes }) ->

  {origin} = global.location

  return "#{if isAbsolute then origin else ''}/Collaboration/#{nickname}/#{channelId}"


