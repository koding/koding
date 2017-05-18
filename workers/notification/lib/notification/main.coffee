process.title = 'koding-notification'
NotificationWorker = require './notificationworker'

notificationWorker = new NotificationWorker
notificationWorker.start()
