{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class WelcomeEmail
  from    = KONFIG.email.defaultFromAddress
  subject = "Welcome to Koding"
  content = "For whome the bell tolls"

  @send = (email, username, callback)->
    JMail = require './email'

    mail = new JMail {email, from, subject, content}
    mail.save callback
