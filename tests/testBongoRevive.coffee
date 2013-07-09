{bongo, Base} = require 'bongo'
assert = require 'assert'
graph = require '../workers/social/lib/social/models/graph/graph.coffee'

JStatusUpdate = require '../workers/social/lib/social/models/messages/statusupdate/index.coffee'
JStatusUpdate.setClient 'localhost:27017/koding'

JStatusUpdate.one {}, (err, jupdate)->
    objid = jupdate.getId()
    console.log "id:", jupdate.getId()

    data = {
        modifiedAt: Date.now(),
        createdAt: Date.now(),
        likes: 0,
        originType: 'JAccount',
        originId: '5196fcb0bc9bdb0000000013',
        id: objid
    }

    jupdateRevived = graph.reviveFromData(data, 'JStatusUpdate')
    console.log ">>>>", jupdateRevived.getId()
    console.log "data.id >>>>", data.id
    assert jupdateRevived.getId() is data.id
    # we dont care about the data at all, just check if function is callable
    jupdateRevived.fetchRelativeComments {limit:10}, (err, data)->
        console.log err, data
        process.exit(0)

