{Model, signature} = require 'bongo'

{ v4: createId } = require 'node-uuid'

getUniqueId = createId

module.exports = class JMail extends Model

  @share()

  @set
    indexes           :
      status          : 'sparse'
    sharedMethods     :
      static          :
        unsubscribeWithId:
          (signature String, String, String, Function)
    sharedEvents      :
      instance        : []
      static          : []
    schema            :
      dateIssued      :
        type          : Date
        default       : -> new Date
      dateAttempted   : Date
      dateDelivered   : Date
      email           :
        type          : String
        email         : yes
      from            :
        type          : String
        email         : yes
        default       : 'hello@koding.com'
      replyto         :
        type          : String
        email         : yes
        default       : 'hello@koding.com'
      status          :
        type          : String
        default       : 'queued'
        enum          : ['Invalid status'
                        [
                          'queued'
                          'sending'
                          'attempted'
                          'failed'
                          'delivered'
                          'unsubscribed'
                        ]]
      smtpId          : String
      redemptionToken : String
      force           :
        type          : Boolean
        default       : false
      subject         : String
      content         : String
      unsubscribeId   : String
      bcc             : String

  save:(callback)->
    @unsubscribeId = getUniqueId()+''  unless @_id? or @force
    super

  isUnsubscribed:(callback)->
    JUnsubscribedMail = require './unsubscribedmail'
    JUnsubscribedMail.isUnsubscribed @email, callback

  @markDelivered = (status, callback = (->)) ->
    smtpId = do ([_, id] = status['smtp-id'].match /^<(.+)>$/) -> id

    unless smtpId?
      return process.nextTick -> callback { message: 'Unknown SMTP id' }

    @one { smtpId }, (err, mail) ->
      return callback err  if err
      return callback { message: 'Unrecognized SMTP id' }  unless mail?

      operation = $set  :
        status          : 'delivered'
        dateDelivered   : status.timestamp * 1000 # milliseconds

      mail.update operation, callback

  @unsubscribeWithId = (unsubscribeId, email, opt, callback)->
    JMail.one {email, unsubscribeId}, (err, mail)->
      return callback err  if err or not mail

      JUnsubscribedMail = require './unsubscribedmail'
      JUnsubscribedMail.one {email}, (err, unsubscribed)->
        return callback err  if err
        return callback null, 'Email was already unsubscribed'  if unsubscribed

        unsubscribed = new JUnsubscribedMail {email}
        unsubscribed.save (err)->
          callback err, unless err then 'Successfully unsubscribed' else null

  @fetchWithUnsubscribedInfo = (selector, options, callback)->
    JUnsubscribedMail = require './unsubscribedmail'

    JMail.some selector, options, (err, mails)->
      return callback err  if err
      return unless mails?.length > 0

      emailsToCheck = (mail.email  for mail in mails when not mail.force)

      JUnsubscribedMail.some email: $in: emailsToCheck, {}, (err, uMails)->
        return callback err  if err

        unsubscribedEmails = (uMail.email  for uMail in uMails)

        cleanedMails = []
        for mail in mails
          unless mail.email in unsubscribedEmails
            cleanedMails.push mail
          else
            mail.update $set: {status: 'unsubscribed'}, (err)->
              # it's not fatal enough to break the process
              # also we don't wait for this to proceed with sending the emails
              # doing a callback(err) here can have unexpected outcomes
              console.log err  if err

        callback null, cleanedMails
