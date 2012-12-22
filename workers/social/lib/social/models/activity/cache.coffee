fs        = require 'fs'
jraphical = require 'jraphical'

module.exports = class JActivityCache extends jraphical.Module

  @share()

  @set
    indexes       :
      to          : 'unique'
    sharedMethods :
      static      : ["latest"]
      instance    : []
    schema        :
      # name        : String
      to          :
        type      : Date
        get       : -> new Date
      from        :
        type      : Date
        default   : -> new Date
      isFull      :
        type      : Boolean
        default   : no
      overview    : Object
      activities  : Array

  latestFetched = null

  o =
    limit : 1
    sort  : to  : 1

  kallback = (err, cache, callback)->
    if err
      callback err
    else if cache
      latestFetched = if cache.data then cache.data
      console.log latestFetched?.to
      callback err, cache.data
    else
      callback null, null


  @latest = (callback)->

    @one {}, o, (err, cache)-> kallback err, cache, callback

  @next = (callback)->

    return @latest callback  unless latestFetched

    selector =
      to     : $gte : latestFetched.to

    @one selector, o, (err, cache)-> kallback err, cache, callback

  @prev = (callback)->

    console.log latestFetched?.to, "<<<<<"

    return @latest callback  unless latestFetched

    selector =
      to     : $lte : latestFetched.to

    @one selector, o, (err, cache)-> kallback err, cache, callback

  @byId = (id, callback)->

    selector = _id : id

    @one selector, o, (err, cache)-> kallback err, cache, callback

  @containsTimestamp = (timestamp, callback)->

    selector = to : $gte : timestamp

    @one selector, o, (err, cache)-> kallback err, cache, callback

  # create initial cache folder
  # do ->

  #   cachePath = "#{__dirname}/../../../../../../website/activitycache/"

  #   fs.mkdir cachePath, (err, res)->
  #     if err
  #       if /EEXIST/.test err
  #         console.warn "Activity cache folder already exists!"
  #       else
  #         console.error "Problem occured while creating activity cache folder!"
  #     else
  #       console.log "Activity cache folder is created!"
