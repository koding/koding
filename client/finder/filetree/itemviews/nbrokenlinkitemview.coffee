NFileItemView = require './nfileitemview'


class NBrokenLinkItemView extends NFileItemView

  constructor:(options = {},data)->

    options.cssClass  or= "broken"
    super options, data


module.exports = NBrokenLinkItemView
