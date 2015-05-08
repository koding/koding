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
    JUser    = require '../user'

    updateSocialAccount = (username)->

      JAccount.one "profile.nickname" : username, (err, account)->
        return console.error err if err?
        return console.error {message: "account is not valid"} unless account?

        SocialAccount.update {
          id   : account.socialApiId
          nick : username
        }, (err)->
          if err?
            console.error "err while updating account in social api", err


    JAccount.on 'UsernameChanged', (data)->
      { oldUsername, username, isRegistration } = data

      unless oldUsername and username
        return console.error "username: #{username} or oldUsername is not set: #{oldUsername}"

      updateSocialAccount username  unless isRegistration

    # we are updating account when we update email because we dont store email
    # in postgres and social parts fetch email from mongo, we are just
    # triggering account update on postgres, so other services can get that
    # event and operate accordingly 
    JUser.on 'EmailChanged', (data)->
      { username } = data

      unless username
        return console.error "username: #{username} is not set"

      updateSocialAccount username
