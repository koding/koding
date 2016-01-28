Machine = require 'app/providers/machine'


module.exports = (machine) -> machine.getIn(['status', 'state']) is Machine.State.Running
