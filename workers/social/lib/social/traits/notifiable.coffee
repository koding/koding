module.exports = class Notifiable

  updateAndNotify: (options, change, callback) ->

    { account, group, target } = options

    id = @getId()

    @update change, (err) ->
      return callback err  if err

      switch target
        when 'group'

          JGroup = require '../models/group'
          JGroup.one { slug : group }, (err, group_) ->
            return callback err  if err

            opts = { id, group, change, timestamp: Date.now() }
            group_?.sendNotification? 'InstanceChanged', opts, callback

        when 'account'

          opts = { id, group, change, timestamp: Date.now() }
          account?.sendNotification? 'InstanceChanged', opts
          callback null

