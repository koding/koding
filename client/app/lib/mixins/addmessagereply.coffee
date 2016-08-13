addMessageReply = (message, reply) ->
  message.replies.push reply
  message.replyIds[reply.id] = yes
  message.repliesCount++

  message.emit 'AddReply', reply
  message.emit 'update'

module.exports = addMessageReply
