GraphDecorator = require '../../server/lib/server/graph/graph_decorator'

data = require('fs').readFileSync './single_activities.sample', 'utf8'
data = JSON.parse data
GraphDecorator.decorateToCacheObject data, (resp)->
  console.log JSON.stringify(resp, null, 3)
