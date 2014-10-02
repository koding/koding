{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class WelcomeEmail
  from    = KONFIG.email.defaultFromAddress
  subject = "Welcome to Koding!"
  content = """
  Hi there!

  Thanks for signing up for Koding. You are awesome!

  Whether you are starting to learn something or looking to tinker with a new project, we hope that Koding will be able to help you achieve your goals.

  We have prepared a lot of introductory material over at http://learn.koding.com . There you will find videos and how-to's on Koding as well as extensive guides on installing and configuring software packages like Wordpress, MySQL, MongoDB, Joomla, etc.

  Last, but not least, we're improving Koding every day so if you encounter any quirks, just drop us a line at support@koding.com.

  Enjoy!
  The Koding Team
"""

  @send = (email, username, callback)->
    JMail = require './email'

    mail = new JMail {email, from, subject, content}
    mail.save callback
