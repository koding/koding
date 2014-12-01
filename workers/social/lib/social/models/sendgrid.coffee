{argv}  = require 'optimist'
KONFIG  = require('koding-config-manager').load("main.#{argv.c}")
request = require "request"

# This modules adds/removes email from Sendgrid's global unsubscribe list.
module.exports = class Sendgrid

  @unsubscribe: (email, callback)->
    request.post @url("unsubscribes.add", email), callback

  @removeUnsubscribe: (email, callback)->
    request.post @url("unsubscribes.delete", email), callback

  @url = (path, email) ->
    url = "https://api.sendgrid.com/api/"
    url += "#{path}.json?"
    url += "api_user=#{KONFIG.sendgrid.username}&"
    url += "api_key=#{KONFIG.sendgrid.password}&"
    url += "email=#{email}"
