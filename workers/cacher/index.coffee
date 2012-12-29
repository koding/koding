{argv}   = require 'optimist'
KONFIG   = require argv.c?.trim()
nodePath = require 'path'

Bongo    = require 'bongo'

{mongo, projectRoot} = KONFIG

koding = new Bongo {
  mongo
  models: [
    'workers/social/lib/social/models/activity/cache.coffee'
  ].map (path)-> nodePath.join projectRoot, path
}

{JActivityCache} = koding.models

do ->
  from = Date.now()-(240*60*60*1000)
  JActivityCache.createCacheBetween from, null, (lolo)->
    console.log lolo

setInterval ->
  console.log "devam"
,10000