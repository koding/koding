{ expect
  ObjectId
  withConvertedUser
  generateRandomString } = require '../../index'

JMachine  = require '../../../../social/lib/social/models/computeproviders/machine'
JSnapshot = require '../../../../social/lib/social/models/computeproviders/snapshot'


createSnapshot = (data, callback) ->

  snapshot = new JSnapshot
    label       : data.label ? generateRandomString()
    region      : data.region ? 'someRegion'
    originId    : data.originId ? new ObjectId
    createdAt   : new Date
    machineId   : data.machineId ? generateRandomString()
    snapshotId  : data.snapshotId ? generateRandomString()
    storageSize : data.storageSize ? '1'

  snapshot.save (err) ->
    return callback err, snapshot


withConvertedUserAndSnapshot = (options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options            ?= {}

  withConvertedUser (data) ->
    { client, userFormData } = data

    JMachine.fetchByUsername userFormData.username, (err, machines) ->
      expect(err).to.not.exist
      options.machineId = machines[0]._id
      options.originId  = client?.connection?.delegate?.getId() ? new ObjectId

      createSnapshot options, (err, snapshot) ->
        expect(err).to.not.exist
        data.snapshot = snapshot
        return callback data


module.exports = {
  withConvertedUserAndSnapshot
}

