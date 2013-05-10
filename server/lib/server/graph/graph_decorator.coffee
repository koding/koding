module.exports = class GraphDecorator

  ResponseDecorator       = require './decorators/response'
  SingleActivityDecorator = require './decorators/single_activity'

  singleActivityDecorators =
    'JTutorial'     : SingleActivityDecorator
    'JCodeSnip'     : SingleActivityDecorator
    'JDiscussion'   : SingleActivityDecorator
    'JStatusUpdate' : SingleActivityDecorator

  @decorateToCacheObject:(data, callback)->
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

    response = (new ResponseDecorator(cacheObjects, overviewObjects)).decorate()
    callback response
