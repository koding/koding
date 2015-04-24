kd     = require 'kd'
remote = require('app/remote').getInstance()


module.exports = class SnapshotHelpers

    ###*
     * Fetch the most recent Snapshot created.
     *
     * @param {String} machineId - The JMachine ID
     * @param {Function(err:Error, snapshot:JSnapshot)} callback
    ###
    @fetchNewestSnapshot: (machineId, callback = kd.noop) ->

      {JSnapshot} = remote.api
      JSnapshot.some { machineId }, { sort: { createdAt: -1 }, limit: 1 },
        (err, snapshots) =>
          return callback err  if err
          if not snapshots
            return callback new Error 'Cannot find most recent snapshot'
          [snapshot] = snapshots
          callback null, snapshot


