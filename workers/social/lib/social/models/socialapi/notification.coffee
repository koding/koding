Bongo          = require "bongo"
{Relationship} = require "jraphical"
request        = require 'request'
KodingError    = require '../../error'

{secure, race, signature, Base} = Bongo
{uniq} = require 'underscore'

module.exports = class SocialNotification extends Base
  @share()

  @trait __dirname, '../../traits/protected'

  @set
    sharedMethods     :
      static          :
        fetch         :
          (signature Function)
        glance        :
          (signature Function)
        follow        :
          (signature Object, Function)
    permissions :
      'list notifications': ['member', 'moderator']
    schema             :
      type             : String
      glanced          : Boolean
      targetId         : Number
      latestActors     : [Number]
      actorCount       : Number
      unreadCount      : Number
      updatedAt        : Date

  {permit}   = require '../group/permissionset'

  JAccount = require '../account'

  @fetch = permit 'list notifications',
    success: (client, callback) ->
      {connection:{delegate}} = client
      {listNotifications} = require './requests'
      delegate.createSocialApiId (err, socialApiId) ->
        return callback err  if err

        # TODO add context and if needed add query string for notification limit
        listNotifications accountId: socialApiId, (err, response) ->
          return callback err  if err

          {notificationList : notifications, unreadCount} = response
          notifications = decorateNotifications notifications
          callback null, {notifications, unreadCount}

  @glance = permit 'list notifications',
    success: (client, callback) ->
      {connection:{delegate}} = client
      {glanceNotifications} = require './requests'
      delegate.createSocialApiId (err, socialApiId) ->
        return callback err  if err
        glanceNotifications socialApiId, (err, response) ->
          return callback err  if err
          return callback {message: "socialapi response error"}  unless response.status
          callback()

  @follow = secure (client, followee, callback)->
    {connection:{delegate}} = client
    return callback new KodingError "Access denied"  if delegate.type isnt 'registered'

    delegate.createSocialApiId (err, actorId) ->
      return callback err  if err
      followee.createSocialApiId (err, targetId) ->
        return callback err  if err
        {createFollowNotification} = require './requests'
        createFollowNotification {actorId, targetId}, (err, response) ->
          return callback err  if err
          return callback {message: "socialapi response error"}  unless response.status
          callback()

  decorateNotifications = (notifications) ->
    notifications = [].concat(notifications)
    revivedNotifications = []
    notifications.map (notification) ->
      n = new SocialNotification notification
      n.type         = notification.typeConstant
      n.targetId     = notification.targetId
      n.latestActors = notification.latestActors
      n.glanced      = notification.glanced
      n.actorCount   = notification.actorCount
      n.updatedAt    = notification.updatedAt
      revivedNotifications.push n


    return revivedNotifications