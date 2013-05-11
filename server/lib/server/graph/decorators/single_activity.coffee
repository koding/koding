BaseDecorator = require './base.coffee'

module.exports = class SingleActivityDecorator extends BaseDecorator
  decorate:->
    response = super
    {activity, overview} = response
    activity.originId    = @datum.originId
    activity.originType  = @datum.originType

    response = {activity, overview}
    return response
