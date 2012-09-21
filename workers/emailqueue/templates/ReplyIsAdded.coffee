nicenames = require '../nicenames'

module.exports = (data)->
  {receiver, email} = data.notification
  {reply, replier, subject} = data.notification.contents
  messageType = nicenames[subject._constructorName]
  {
    To        : email
    From      : 'hi@koding.com'
    Subject   : 
      "[Koding] #{replier.profile.firstName} #{replier.profile.lastName} replied to your #{messageType}"
    TextBody  :
      """
      Hey-o #{receiver.profile.firstName} #{receiver.profile.lastName},

      #{replier.profile.firstName} #{replier.profile.lastName} replied to your #{messageType}.

      That's all I know.

      Peace
      A clueless robot.
      """
  }