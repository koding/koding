utils              = require '../utils/utils.js'
teamsHelpers       = require '../helpers/teamshelpers.js'
teambillinghelper  = require '../helpers/teambillinghelpers.js'
async = require 'async'

module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()


  teambilling: (browser) ->

    queue = [
      (next) ->
        teambillinghelper.seeAvailablePaymentSubscription browser, (result) ->
          next null, result
      (next) ->
        teambillinghelper.redirectPricingDetails browser, (result) ->
          next null, result
      (next) ->
        teambillinghelper.redirectViewMembers browser, (result) ->
          next null, result
      (next) ->
        teambillinghelper.enterCreditCard browser, (result) ->
          next null, result
      (next) ->
        teambillinghelper.redirectPaymentHistory browser, (result) ->
          next null, result

    ]

    async.series queue


  after: (browser) ->
    browser.end()
