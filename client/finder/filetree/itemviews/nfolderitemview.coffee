NFileItemView = require './nfileitemview'


class NFolderItemView extends NFileItemView

  constructor:(options = {},data)->

    options.cssClass  or= "folder"
    super options, data


module.exports = NFolderItemView
