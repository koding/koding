kd                    = require 'kd'
SidebarMoreLink       = require './sidebarmorelink'


module.exports = class SidebarMoreLink extends SidebarMoreLink

  constructor: (options = {}, data) ->

    super options, data


  renderCount: (err, res) ->

    return  if err

    { limit }           = @getOptions()
    { totalCount }      = res

    if totalCount + 2 > limit
    then @show()
    else @hide()


