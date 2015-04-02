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
    WELCOME          : 'Welcome to Koding!'
    INVITE           : 'invite'
    FEEDBACK         : 'feedback'
    USERNAME_CHANGED : 'username_changed'
    PASSWORD_CHANGED : 'password_changed'


  queue: (username, mail, options, callback)->
    mail.to           = forcedRecipient or mail.to
    mail.from       or= defaultFromMail
    mail.properties   = { options, username}

    @emit 'messageBusEvent', {type : 'api.mail_send', message: mail}

    callback null
