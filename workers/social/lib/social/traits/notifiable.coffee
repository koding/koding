module.exports = class Notifiable

  updateAndNotify: (options, change, callback) ->

    @update change, (err) =>

      options?.account?.sendNotification? 'InstanceChanged', {
        id: @getId(), group: options.group, change, timestamp: Date.now()
      }

      callback err
