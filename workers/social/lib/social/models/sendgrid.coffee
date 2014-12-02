{argv}  = require 'optimist'
KONFIG  = require('koding-config-manager').load("main.#{argv.c}")
request = require "request"

# This module manages subscriptions of user emails to
module.exports = class Sendgrid

  ALL_USERS = "allusers"
  MARKETING = "marketing"

  @addNewUser: (email, name, callback)->
    @addToAllUsers email, name, =>
      @addToMarketing email, name, callback

  @addToAllUsers: (email, name, callback)->
    @addEmail ALL_USERS, email, name, callback

  @addToMarketing: (email, name, callback)->
    @addEmail MARKETING, email, name, callback

  @deleteFromMarketing: (email, callback)->
    @delEmail MARKETING, email, callback

  @addEmail: (list, email, name, callback)->
    data = JSON.stringify({email, name})
    url  = @url("newsletter/lists/email/add", "list=#{list}&data=#{data}")

    request.post url, callback

  @delEmail: (list, email, callback)->
    url = @url("newsletter/lists/email/delete", "list=#{list}&email=#{email}")
    request.post url, callback

  @url= (path, opt)->
    url = "https://api.sendgrid.com/api/"
    url += "#{path}.json?"
    url += "api_user=#{KONFIG.sendgrid.username}&"
    url += "api_key=#{KONFIG.sendgrid.password}&"
    url += opt

    return url
