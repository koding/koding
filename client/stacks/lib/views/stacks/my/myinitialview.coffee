BaseInitialView = require '../baseinitialview'


module.exports = class MyInitialView extends BaseInitialView


  constructor: (options = {}, data) ->

    options.listViewOptions =
      viewType              : 'private'

    super options, data
