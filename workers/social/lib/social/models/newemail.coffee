bongo  = require 'bongo'
{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

KodingError = require '../error'

module.exports = class NewEmail extends bongo.Base

  {forcedRecipient, defaultFromMail} = KONFIG.email

  @set
    sharedEvents  :
      instance : [ {name : 'messageBusEvent'} ]

  @types =
    WELCOME_EMAIL : 'welcomeEmail'

  queue: (mail, callback)->
    mail.to           = forcedRecipient or mail.to
    mail.from       or= defaultFromMail
    mail.properties or= {}

    keys = [ 'to', 'subject', 'username' ]
    for param in keys when not mail[param]
      return callback {message: "#{param} is required"}

    @emit 'messageBusEvent', {type : 'api.mail_send', message: mail}

    callback null
