{Model} = require 'bongo'

# TODO Implement a global unsubscribe for all e-mails

module.exports = class JMail extends Model

  @share()

  @set
    indexes          :
      status         : 'sparse'
    # sharedMethods    :
    #   static         : ['unsubscribeWithId']
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
        enum         : ['Invalid status', ['queued', 'attempted',
                                           'sending', 'failed']]
      subject        : String
      content        : String
      # unsubscribeId  : String
