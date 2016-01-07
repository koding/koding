kd = require 'kd'
JView = require 'app/jview'


module.exports = class ActivityBaseWidget extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'activity-widget', options.cssClass

    super options, data
