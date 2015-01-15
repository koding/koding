WorkspaceTabView = require '../../workspace/workspacetabview'


class IDESocialsTabView extends WorkspaceTabView

  constructor: (options = {}, data) ->

    options.addPlusHandle = no

    super options, data


module.exports = IDESocialsTabView
