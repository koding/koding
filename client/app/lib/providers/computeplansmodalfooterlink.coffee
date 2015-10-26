kd              = require 'kd'
CustomLinkView  = require '../customlinkview'


module.exports = class ComputePlansModalFooterLink extends CustomLinkView


  constructor: (options = {}, data) ->

    options.href or= '/Pricing'

    super options, data


  click: -> off
