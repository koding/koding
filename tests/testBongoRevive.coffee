{Base} = require 'bongo'



KONFIG = require('koding-config-manager').load("main.vagrant")

assert = require 'assert'
Graph = require '../workers/social/lib/social/models/graph/graph.coffee'

JStatusUpdate = require '../workers/social/lib/social/models/messages/statusupdate/index.coffee'
JStatusUpdate.setClient 'localhost:27017/koding'


getOneDummy = (callback)->
  # TODO: this is a dummy method just to try, delete before you push
  query = 'start koding=node:koding(id=\'51db01eec9acdc0000000007\')
      MATCH koding<-[:follower]-myfollowees-[:author]-content
      where myfollowees.name="JAccount"
      AND content.group = "koding"
      AND (content.name=\'JStatusUpdate\')
      return distinct content
      order by content.`meta.createdAtEpoch` DESC
      LIMIT 1'
  try
    options = {}
    graph = new Graph({config:KONFIG['neo4j']})
    options.returnAsBongoObjects = true
    graph.runQuery(query, options, callback)
  catch e 
    console.log ">>>>", e 

getOneDummy (err, data)->
  console.log data[0].getId()
  assert data[0].getId()
  process.exit(0)


# JStatusUpdate.one {}, (err, jupdate)->
#     objid = jupdate.getId()
#     console.log jupdate
#     console.log "id:", jupdate.getId()

#     data = {
#         modifiedAt: Date.now(),
#         createdAt: Date.now(),
#         likes: 0,
#         originType: 'JAccount',
#         originId: '5196fcb0bc9bdb0000000013',
#         id: objid
#     }


#     jupdateRevived = Graph.reviveFromData(data, 'JStatusUpdate')
#     console.log ">>>>", jupdateRevived.getId()
#     console.log "data.id >>>>", data.id
#     assert jupdateRevived.getId() is data.id
#     console.log "=============="
#     console.log jupdateRevived
#     console.log "//============"
#     # we dont care about the data at all, just check if function is callable
#     jupdateRevived.fetchRelativeComments {limit:10}, (err, data)->
#         console.log err, data
#         process.exit(0)



