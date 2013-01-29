{CronJob}       = require 'cron'
{EventEmitter}  = require 'events'
{dash}          = require 'sinkrow'

ObjectRef = require './objectref'

module.exports = class EmailQueue extends EventEmitter
  constructor:(@db)->
    @tasks          = {}
    @notifications  = db.collection 'jEmailNotifications'
    @users          = db.collection 'jUsers'

  scheduleTask:(taskName, cronTime, fn)->
    job = new CronJob cronTime, fn
    job.start()
    @tasks[taskName] = job

  cancelTask:(taskName)->
    @tasks[taskName].stop()

  removeItem:(notification)->
    console.log 'Attempting to remove an item.', notification._id
    @notifications.removeById notification._id, (err)->
      if err
        console.log 'There was an error deleting the queued notification'
        console.log err
      else
        console.log 'Notification is removed'

  markAsAttempted:(notification)->
    @notifications.update {_id: notification._id}, {$set: status: 'attempted'},
      (err)-> if err then console.log 'There was an error', err

  next:-> if ++@index is @length then @emit 'QueueIsEmpty', @length

  populateObjectRefs:(ctx, callback)->
    objectRefs = []
    Object.keys(ctx).forEach (key)=>
      value = ctx[key]
      if ObjectRef.isObjectRef(value)
        objectRefs.push =>
          ObjectRef.populate @db, value, (err, populated)->
            if populated?
              populated._constructorName = value.constructorName
              ctx[key] = populated
            objectRefs.fin()
    dash objectRefs, callback

  forEach:(callback)->
    @index = 0
    @notifications.find status: 'queued', (err, cursor)=>
      if err
        callback err
      else cursor.count (err, count)=>
        if err
          callback err
        else if count is 0
          @emit 'QueueIsEmpty', 0
        else
          @length = count
          cursor.each (err, notification)=>
            if err
              callback err
            else unless notification?
              console.log 'Done handling all queued notifications.'
              callback null
            else
              @users.findOne {
                email: notification.email
              }, (err, user)=>
                @populateObjectRefs notification.contents, ->
                  callback err, notification, user