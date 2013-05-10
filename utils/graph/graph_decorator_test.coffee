GraphDecorator = require '../../server/lib/server/graph/graph_decorator'

#data = require('fs').readFileSync './fixtures/single_activities.sample', 'utf8'
#data = JSON.parse data
#GraphDecorator.decorateSingleActivities data, (resp)->
  #console.log JSON.stringify(resp, null, 3)

data = require('fs').readFileSync './fixtures/follows_bucket.sample', 'utf8'
data = JSON.parse data
GraphDecorator.decorateFollows data, (resp)->
  console.log JSON.stringify(resp, null, 3)

#data = require('fs').readFileSync './fixtures/installs_bucket.sample', 'utf8'
#data = JSON.parse data
#GraphDecorator.decorateInstalls data, (resp)->
  #console.log JSON.stringify(resp, null, 3)
