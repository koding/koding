kd = require 'kd'

module.exports = helpers =

  markAsLoaded: (templateId, stackId) ->

    kd.singletons.sidebar.setSelected { templateId, stackId, machineId: null }


  log: (rest...) ->

    console.log '[NewStackEditor]', rest...
