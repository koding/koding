nicenames = require '../nicenames'

module.exports = (data)->
  {receiver}  = data.notification
  {reply, replier, subject}   = data.notification.contents
  messageType = nicenames[subject._constructorName]
  {
    Subject: 
      "#{replier.profile.firstName} #{replier.profile.lastName} replied to your #{messageType}"
    TextBody:
      """
      Hey #{receiver.profile.firstName} #{receiver.profile.lastName},

      #{replier.profile.firstName} #{replier.profile.lastName} replied to your #{messageType}.

      That's all I know.

      Peace
      A clueless robot.
      """
  }