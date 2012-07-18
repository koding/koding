log4js  = require 'log4js'
log     = log4js.addAppender log4js.fileAppender("/var/log/fsWatcherApi.log"), "[fsWatcherApi]"
log     = log4js.getLogger('[fsWatcherApi]')
path    = require 'path'
{exec}  = require 'child_process'

{EventEmitter} = require 'events'
{Inotify} = require 'inotify'

config =
  maxWatches : 10000


class FsWatcherApi extends EventEmitter

  constructor : (@config) ->
    @inotify = new Inotify
    @watchers = {}
    @watchersNum = 0
    @maxWatches = @config.maxWatches

    exec "/sbin/sysctl -w fs.inotify.max_user_watches=#{@maxWatches}",(err,stdout,stderr)=>
      if err?
        log.error "[ERROR] can't set maxWatches to #{@maxWatches}: #{stderr}"
        process.exit 1
      else
        log.info "[OK] fsWatcher started, and can watch inside #{@maxWatches} dirs"


  removeWatcher : (options,callback)->

    {dir} = options

    log.info "removing watch descriptor #{@watchers[dir]} for #{dir}"
    try
      if @inotify.removeWatch(@watchers[dir])
        @watchersNum = @watchersNum - 1
        log.info "number of inotify watches after removeWatch: #{@watchersNum}"
        delete @watchers[dir]
        #log.debug @watchers
        callback? true
      else
        callback? false
    catch TypeError
      log.warn "cant find watch descritor for #{dir}, probably already removed"
      callback? true

  watchForDir : (options,callback)->

    {dir,eventID} = options

    receiver = (event)=>

      mask = event.mask
      name = event.name
      type = (if mask & Inotify.IN_ISDIR then "directory" else "file")


      if mask & Inotify.IN_CREATE
        result =
          path:path.join dir,name
          type:type
          watchPath: dir
          event:'created'
          inotifyEvent:'IN_CREATE'
        log.info result
        # this guy is emitting to the instance
        @emit eventID,result

      else if mask & Inotify.IN_DELETE
        result =
          path:path.join dir,name
          type:type
          watchPath: dir
          event:'deleted'
          inotifyEvent:'IN_DELETE'
        log.info result
        @emit eventID, result

      else if mask & Inotify.IN_MOVED_FROM
        result =
          path:path.join dir,name
          type:type
          watchPath: dir
          event:'deleted'
          inotifyEvent:'IN_MOVED_FROM'
        log.info result
        @emit eventID,result

      else if mask & Inotify.IN_MOVED_TO
        result =
          path:path.join dir,name
          type:type
          watchPath: dir
          event:'created'
          inotifyEvent:'IN_MOVED_TO'
        log.info result
        @emit eventID, result

    watchObj =
      path : dir
      watch_for: Inotify.IN_CREATE | Inotify.IN_DELETE | Inotify.IN_MOVED_FROM | Inotify.IN_MOVED_TO
      callback : receiver



    if @watchers[dir]?
      log.warn "[WARN] #{dir} already under inotify, removing an old watch descritor #{@watchers[dir]} and creating new one for new listener "
      if @inotify.removeWatch(@watchers[dir])
        wd = @inotify.addWatch(watchObj)
        @watchers[dir]=wd
      callback? null,"[WARN] #{dir} already under inotify, removing an old watch descritor and creating new one for new listener"
    else
      if @watchersNum > @maxWatches
        log.error "[ERROR] Can't accept more than #{@watchersNum} dirs. Encrease maxWatches"
        #TODO:email this error or add as  zabbix triger
        callback? "[ERROR] Can't accept more than #{@watchersNum} dirs. Encrease maxWatches"
      else
        wd = @inotify.addWatch(watchObj)
        @watchers[dir]=wd
        #log.debug @watchers
        @watchersNum = @watchersNum + 1
        log.info "[OK] #{dir} is under inotify now, number of watches now: #{@watchersNum}"
        callback? null,null,"[OK] #{dir} is under inotify now, number of watches now: #{@watchersNum}"


fsWatcher = new FsWatcherApi(config) # exporting object
module.exports = fsWatcher

#fsWatcher.watchForDir dir:'/tmp'
#fsWatcher.addListener "fschange",()->
#  console.log "yo"


