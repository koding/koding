JUser     = require './models/user'
JAccount  = require './models/account'

amqp = require 'amqp'

USER_EXCHANGE_OPTIONS =
  type        : 'direct'
  autoDelete  : no
  durable     : yes

followMQ = amqp.createConnection KONFIG.followfeed

fetchExchangePair = (followerName, followeeName, callback) ->
  followMQ.exchange followerName, USER_EXCHANGE_OPTIONS, (follower) ->
    followMQ.exchange followeeName, USER_EXCHANGE_OPTIONS, (followee) ->
      callback follower, followee

followHelper = (follower, followee, method)->
  followerName  = follower.profile.nickname
  followeeName  = followee.profile.nickname
  fetchExchangePair followerName, followeeName, (follower, followee) ->
    follower[method] followee, followeeName
    follower.close()
    followee.close()

followMQ.on 'ready', ->

  JUser.on 'UserCreated',  (user) ->
    console.log 'a user is created'
    followMQ.exchange user.username, USER_EXCHANGE_OPTIONS, (exchange) ->
      console.log {exchange}
      # don't leak a channel; gotta love this driver!
      exchange.close()

  JAccount.on 'FollowHappened', ({ followee, follower })->
    followHelper follower, followee, 'bind'

  JAccount.on 'UnfollowHappened', ({ followee, follower })->
    followHelper follower, followee, 'unbind'
