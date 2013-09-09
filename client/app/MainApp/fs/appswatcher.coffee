
class AppsWatcher extends FSWatcher

  # Emits following signals:
  #
  #  - NewAppIsAdded
  #  - FileIsRemoved
  #  - AppIsRemoved
  #  - FileHasChanged
  #  - ManifestHasChanged
  #
  # All includes (app, change) as parameter

  constructor:(options={})->
    options.path = "~/Applications"
    super options
    @_trackedApps = []

  fileRemoved:(change)->
    app = getAppName change
    if (isKdApp change) or (isManifest change)
      @_trackedApps = (_app for _app in @_trackedApps when _app isnt app)
      # log "An app removed:", app
      throttle => @emit "AppIsRemoved", app, change
    else if isInKdApp change
      log "A file '#{change.file.name}' removed from #{app} app."
      throttle => @emit "FileIsRemoved", app, change

  fileAdded:(change)->
    app = getAppName change
    if isInKdApp change
      if isManifest change
        log "A manifest changed/added:", app
        if app in @_trackedApps
          throttle => @emit "ManifestHasChanged", app, change
        else
          @_trackedApps.push app
          # log "A new app added:", app
          throttle => @emit "NewAppIsAdded", app, change
      else
        throttle => @emit "FileHasChanged", app, change

  # Helpers
  isKdApp    = (change)-> /\.kdapp$/.test change.file.fullPath
  isInKdApp  = (change)-> /Applications\/.*\.kdapp/.test change.file.fullPath
  isManifest = (change)-> /manifest\.json$/.test change.file.fullPath
  getAppName = (change)->
    (change.file.fullPath.match /Applications\/([^\/]+)\.kdapp/)[1]
  throttle   = (cb)-> do KD.utils.throttle cb, 300
