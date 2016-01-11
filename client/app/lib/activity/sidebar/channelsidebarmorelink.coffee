kd                    = require 'kd'
SidebarMoreLink       = require './sidebarmorelink'


module.exports = class ChannelSidebarMoreLink extends SidebarMoreLink

  renderCount: (err, res) ->

    return  if err

    { totalCount } = res

    if totalCount > 8
    then @show()
    else @hide()
