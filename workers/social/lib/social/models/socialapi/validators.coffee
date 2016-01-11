{ any } = require '../group/validators'

{ checkOwnership } = require './requests'

module.exports =

  own: (client, group, permission, permissionSet, args, callback) ->
    any.call this, client, group, permission, permissionSet, args,
      (err, hasPermission) =>
        return callback err, no   if err?
        return callback null, no  if hasPermission is no

        client.connection.delegate.createSocialApiId (err, accountId) =>
          return callback err  if err?

          [options] = args
          [type, objectId] = switch @name
            when 'SocialChannel'
              [
                'channel'
                options.channelId
              ]
            when 'SocialMessage'
              [
                'channel-message'
                options.messageId
              ]

          checkOwnership { accountId, objectId, type }, (err, res) ->
            return callback err, no  if err?
            return callback null, res.success
