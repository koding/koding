bongo          = require 'bongo'
{EventEmitter} = require 'events'

hat            = require 'hat'


watchersPool = []

Array::findAndRemove = (dir)->
  __tmpArray = []
  for obj in @
    if obj.dir isnt dir
      __tmpArray.push obj
    else
      removedElement = obj
  return newArray:__tmpArray,removedElement:removedElement

bongo.client.connect
  host:"cl0.dev.srv.kodingen.com"
  port:4500
  reconnect: 1000
, (api)->

  api.KodingApi.getKites (err,kites)->
    console.log err if err?

    fschanges = kites.fsWatcherKitesTest.api
    console.log kites.fsWatcherKitesTest

    fschanges.on "cleanedup",(msg)->
      id = hat()
      console.log "yo cleanuper! I need  dir #{msg.dir}"
      console.log "adding new watch with eventID: random#{id}"
      watchersPool = watchersPool.findAndRemove(msg.dir).newArray
      watchersPool.push eventID:id,dir:msg.dir
      fschanges.watch dir:msg.dir,eventID:"random#{id}"
      fschanges.on "random#{id}",(msg)->
        console.log msg

    id = 500
    while id > 0
      event = "random#{id}"
      dir   = "/Users/eventtest/dir#{id}"
      watchersPool.push eventID:event,dir:dir
      fschanges.watch dir: dir,eventID:event
      fschanges.on event,(msg)->
        console.log msg
      id -= 1

    api.KodingApi.on "newKite",(name,kite)->
      console.log "backend #{name} is just (re)connected."
      console.log "now I have to add #{watchersPool.length} watchers again"


   # id = 14
   # event = "random#{id}"
#    fschanges.watch dir: "/tmp/event/dir4",eventID:event
#    fschanges.on event,(msg)->
#      console.log msg
#



#    fschanges.removeWatch dir:"/tmp/event/dir20",eventID:'random20',(err)->
