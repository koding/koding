NFileItemView = require './nfileitemview'
module.exports = class NFolderItemView extends NFileItemView

  constructor: (options = {}, data) ->

    options.cssClass  or= 'folder'
    super options, data
