Bongo          = require "bongo"

{Base} = Bongo


# this file named as socialaccount while it is under social folder, because i
# dont want it to be listed first item while searching for account.coffe in
# sublime ~ CS
module.exports = class SocialAccount extends Base
  JAccount = require '../account'

  Validators = require '../group/validators'

  { bareRequest } = require "./helper"

  @update = (args...)-> bareRequest 'updateAccount', args...

  do ->

    JAccount = require '../account'
    JAccount.on 'UsernameChanged', ({ oldUsername, username, isRegistration })->

      unless oldUsername and username
        return console.error "username: #{username} or oldUsername is not set: #{oldUsername}"


      unless isRegistration
        JAccount.one "profile.nickname" : username, (err, account)->
          return console.error err if err?
          return console.error {message: "account is not valid"} unless account?

          SocialAccount.update {
            id   : account.socialApiId
            nick : username
          }, (err)->
            if err?
              console.error "err while changing the nickname in social api", err
