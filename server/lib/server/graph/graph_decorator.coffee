module.exports = class GraphDecorator
  ResponseDecorator       = require './decorators/response'
  SingleActivityDecorator = require './decorators/single_activity'
  FollowsBucketDecorator  = require './decorators/follow_bucket'
  InstallsBucketDecorator = require './decorators/installs_bucket'

  singleActivityDecorators =
    'JTutorial'     : SingleActivityDecorator
    'JCodeSnip'     : SingleActivityDecorator
    'JDiscussion'   : SingleActivityDecorator
    'JStatusUpdate' : SingleActivityDecorator

  @decorateSingleActivities:(data, callback)->
    cacheObjects    = {}
    overviewObjects = []

    for datum in data
      if klass = singleActivityDecorators[datum.name]
        {activity, overview} = (new klass(datum)).decorate()
      else
        console.log datum.name, "not implemented"
        activity = {}
        overview = []

      cacheObjects[datum._id] = activity
      overviewObjects.push overview

    callback {cacheObjects, overviewObjects}

  @decorateFollows:(data, callback)->
    cacheObjects    = {}
    overviewObjects = []

    resp = (new FollowsBucketDecorator(data)).decorate()
    callback resp

    #cacheObjects[activity] = activity
    #overviewObjects.push overview
    #callback {cacheObjects, overviewObjects}

  @decorateInstalls:(data, callback)->
    resp = (new InstallsBucketDecorator(data)).decorate()
    callback resp

  ## TODO: move these to ResponseDecorator ##
  #@decorateSingle:(data, callback)->
    #{cacheObjects, overviewObjects} = @decorateSingleToCacheObject data, callback
    #response = @decorateResponse cacheObjects, overviewObjects

    #callback response

  #@decorateFollows:(data, callback)->
    #{cacheObjects, overviewObjects} = @decorateFollowsToCacheObject data, callback
    #response = @decorateResponse cacheObjects, overviewObjects

    #callback response

  #@decorateResponse:(cacheObjects, overviewObjects)->
    #return (new ResponseDecorator(cacheObjects, overviewObjects)).decorate()
