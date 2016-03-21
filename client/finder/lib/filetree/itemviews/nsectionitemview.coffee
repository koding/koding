NFileItemView = require './nfileitemview'
module.exports = class NSectionItemView extends NFileItemView

  constructor: (options = {}, data) ->

    options.cssClass  or= 'section'
    super options, data
