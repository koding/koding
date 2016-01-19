NFinderController = require 'finder/filetree/controllers/nfindercontroller'


module.exports = class IDEFinderController extends NFinderController


  updateMachineRoot: (uid, path, callback) ->

    super

    @emit 'RootFolderChanged', path  unless @dontEmitChangeEvent
