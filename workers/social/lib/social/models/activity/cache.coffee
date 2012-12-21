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

  @latest = (callback)->

    options =
      sort  :
        to  : 1
      limit : 1

    @one {}, options, (err, cache)->
      if err then console.warn err
      # delete cache.data
      callback err, cache.data


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
