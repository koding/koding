GoogleDriveRealtimeManager    = require './googledriverealtimemanager'
FirebaseRealtimeManager       = require './firebaserealtimemanager'
kd                            = require 'kd'
KDObject                      = kd.Object
IDEMetrics                    = require './idemetrics'

module.exports = class RealtimeManagerFactory extends KDObject

  get: (type) ->
      if type is 'FIREBASE'
        realtime = new FirebaseRealtimeManager()
      else if type is 'GOOGLE_DRIVE'
        realtime = new GoogleDriveRealtimeManager()
      return realtime
  
