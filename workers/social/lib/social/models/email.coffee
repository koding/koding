{Model} = require 'bongo'

createId = require 'hat'
getUniqueId= -> createId 256

module.exports = class JMail extends Model

  @share()

  @set
    indexes          :
      status         : 'sparse'
    sharedMethods    :
      static         : ['unsubscribeWithId']
    schema           :
      dateIssued     :
        type         : Date
        default      : -> new Date
      dateAttempted  : Date
      email          :
        type         : String
        email        : yes
      from           :
        type         : String
        email        : yes
        default      : 'hello@koding.com'
      replyto        :
        type         : String
        email        : yes
        default      : 'hello@koding.com'
      status         :
        type         : String
        default      : 'queued'
        enum         : ['Invalid status', ['queued', 'attempted', 'sending', 
                                           'failed', 'unsubscribed']]
      force          :
        type         : Boolean
        default      : false
      subject        : String
      content        : String
      unsubscribeId  : String

  save:(callback)->
    @unsubscribeId = getUniqueId()+''  unless @_id? or @force
    super

  isUnsubscribed:(callback)->
    JUnsubscribedMail = require './unsubscribedmail'
    JUnsubscribedMail.isUnsubscribed @email, callback

  @unsubscribeWithId = (unsubscribeId, opt, callback)->
    JMail.one {unsubscribeId}, (err, mail)->
      return callback err  if err or not mail

      selector = {email: mail.email}
      JUnsubscribedMail = require './unsubscribedmail'
      JUnsubscribedMail.one selector, (err, unsubscribed)->
        return callback err  if err or unsubscribed

        unsubscribed = new JUnsubscribedMail selector
        unsubscribed.save (err)->
          callback err, unless err then 'Successfully unsubscribed' else null
