module.exports = helpers =

  markAsLoaded: (stackTemplateId) ->

    EnvironmentFlux = require 'app/flux/environment'

    { setSelectedMachineId, setSelectedTemplateId } = EnvironmentFlux.actions
    setSelectedTemplateId stackTemplateId
    setSelectedMachineId null

  log: (rest...) ->

    console.log '[NewStackEditor]', rest...
