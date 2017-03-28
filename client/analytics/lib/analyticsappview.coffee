kd = require 'kd'
JView = require 'app/jview'

module.exports = class AnalyticsAppView extends JView

  constructor: (options = {}, data) ->

    options.testPath   = 'analytics'
    options.cssClass or= kd.utils.curry 'AnalyticsAppView', options.cssClass

    super options, data

  pistachio: ->
    '''
    <iframe src="http://192.168.59.103:1903" frameborder="0"></iframe>
    '''
