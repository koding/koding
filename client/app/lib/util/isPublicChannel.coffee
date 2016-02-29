module.exports = isPublicChatChannel = (channel) ->

  return not (channel.typeConstant in ['privatemessage', 'collaboration', 'bot', 'announcement'])
