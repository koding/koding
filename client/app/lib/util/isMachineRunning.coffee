Machine = require 'app/providers/machine'


module.exports = (machine) -> machine.toJS().status.state is Machine.State.Running
