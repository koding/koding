module.exports = class Notifiable

  updateAndNotify: (options, change, callback) ->

    @update change, (err) =>

      options?.account?.sendNotification? 'InstanceChanged', {
        id: @getId(), group: options.group
      }

      callback err
