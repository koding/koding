getGroup = require 'app/util/getGroup'

module.exports = getChannelTypeByName = (name) ->

  type = switch name
    when 'public'                     then 'group'
    when 'changelog', getGroup().slug then 'announcement'
    else 'topic'


