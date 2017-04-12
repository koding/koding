kd = require 'kd'

module.exports = helpers =

  markAsLoaded: (templateId, stackId, machineId) ->

    kd.singletons.sidebar.setSelected { templateId, stackId, machineId }


  log: (rest...) ->

    console.log '[NewStackEditor]', rest...
