bongo  = require 'bongo'
{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

KodingError = require '../error'

module.exports = class NewEmail extends bongo.Base

  {forcedRecipient, defaultFromMail} = KONFIG.email

  @set
    sharedEvents  :
      instance : [ {name : 'messageBusEvent'} ]

  VERSION_1 = ' v1'

  @types =
    WELCOME          : 'welcome'          + VERSION_1
    INVITE           : 'invite'           + VERSION_1
    FEEDBACK         : 'feedback'         + VERSION_1
    EMAIL_CHANGED    : 'email changed'    + VERSION_1
    PASSWORD_CHANGED : 'password changed' + VERSION_1
    CONFIRM_EMAIL    : 'confirm email'    + VERSION_1


  queue: (username, mail, options, callback)->
    mail.to           = forcedRecipient or mail.to
    mail.from       or= defaultFromMail
    mail.properties   = { options, username}

    @emit 'messageBusEvent', {type : 'api.mail_send', message: mail}

    callback null
