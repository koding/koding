Bongo            = require 'bongo'
{ Relationship } = require 'jraphical'
request          = require 'request'
KodingError      = require '../../error'

{ secure, race, signature, Base } = Bongo
{ uniq } = require 'underscore'

module.exports = class SocialNotification extends Base
  @share()

  @trait __dirname, '../../traits/protected'

  @set
    sharedMethods     :
      static          :
        fetch         :
          (signature Object, Function)
        glance        :
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

  { permit }   = require '../group/permissionset'

  { doRequest } = require './helper'

  JAccount = require '../account'

  @fetch = secure (client, options, callback) ->
    doRequest 'listNotifications', client, options, (err, response) ->
      return callback err if err?
      { notificationList : notifications, unreadCount } = response
      notifications = decorateNotifications notifications
      callback null, { notifications, unreadCount }

  @glance = secure (client, options, callback) ->
    doRequest 'glanceNotifications', client, {}, callback

  decorateNotifications = (notifications) ->
    notifications = [].concat(notifications)
    revivedNotifications = []
    notifications.map (notification) ->
      n = new SocialNotification notification
      n.type         = notification.typeConstant
      n.targetId     = notification.targetId
      n.latestActors = notification.latestActorsOldIds
      n.glanced      = notification.glanced
      n.actorCount   = notification.actorCount
      n.updatedAt    = notification.updatedAt
      revivedNotifications.push n


    return revivedNotifications
