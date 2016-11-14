KodingError = require '../error'

module.exports = class Notifiable

  updateAndNotify: (options, change, callback) ->

    { account, group, target } = options

    id = @getId()

    @update change, (err) ->

      callback err

      switch target

        when 'group'

          return  unless group

          JGroup = require '../models/group'
          JGroup.one { slug : group }, (err, group_) ->
            return  if err or not group_

            opts = { id, group, change, timestamp: Date.now() }
            group_.sendNotification 'InstanceChanged', opts

        when 'account'

          return  unless account

          opts = { id, group, change, timestamp: Date.now() }
          account.sendNotification 'InstanceChanged', opts


  removeAndNotify: (options, callback) ->

    { account, group, target } = options

    id = @getId()

    @remove (err) ->

      callback err

      switch target
        when 'group'

          return  unless group

          JGroup = require '../models/group'
          JGroup.one { slug : group }, (err, group_) ->
            return  if err or not group_

            opts = { id, group, timestamp: Date.now() }
            group_.sendNotification 'InstanceDeleted', opts

        when 'account'

          return  unless account

          opts = { id, group, timestamp: Date.now() }
          account.sendNotification 'InstanceDeleted', opts


