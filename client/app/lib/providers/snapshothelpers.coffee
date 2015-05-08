kd                        = require 'kd'
remote                    = require('app/remote').getInstance()

EnvironmentsProgressModal = require './environmentsprogressmodal'


###*
 * Fetch the most recent Snapshot created.
 *
 * @param {String} machineId - The JMachine ID
 * @param {Function(err:Error, snapshot:JSnapshot)} callback
###
fetchNewestSnapshot = (machineId, callback = kd.noop) ->

  {JSnapshot} = remote.api
  JSnapshot.some { machineId }, { sort: { createdAt: -1 }, limit: 1 },
    (err, snapshots) =>
      return callback err  if err
      unless snapshots
        return callback new Error 'Cannot find most recent snapshot'
      [snapshot] = snapshots
      callback null, snapshot


###*
 * Show the snapshotting modal (EnvironmentsProgressModal)
 *
 * @param {KDView} container - A view that the Modal will overlay (usually
 *  the IDE)
 * @param {actionLabel} actionLabel - the action label used in the modal.
 * @returns {EnvironmentsProgressModal}
###
showSnapshottingModal = (machine, container) ->

  modal = new EnvironmentsProgressModal
    container          : container
    actionLabel        : 'Creating a snapshot'
    customErrorMessage : """
      <p>Snapshot creation failed.</p>
      <span>
        Please <span class="close">close this message</span> or
        <span class="contact-support">contact support</span> for
        further assistance.
      </span>
    """
    machine
  modal.show()


module.exports = {
  fetchNewestSnapshot
  showSnapshottingModal
}


