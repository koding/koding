IDEWorkspaceTabView = require '../../workspace/ideworkspacetabview'
module.exports = class IDESocialsTabView extends IDEWorkspaceTabView

  constructor: (options = {}, data) ->

    options.addPlusHandle = no

    super options, data
