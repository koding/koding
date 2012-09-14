nicenames = require '../nicenames'

module.exports = (data)->
  {receiver, email} = data.notification
  {liker, subject} = data.notification.contents
  messageType = nicenames[subject._constructorName]
  {
    To        : email
    From      : 'hi@koding.com'
    Subject   : 
      "[Koding] #{liker.profile.firstName} #{liker.profile.lastName} liked to your #{messageType}"
    TextBody  :
      """
      Hey-o #{receiver.profile.firstName} #{receiver.profile.lastName},

      #{liker.profile.firstName} #{liker.profile.lastName} liked to your #{messageType}.

      That's all I know.

      Peace
      A clueless robot.
      """
  }