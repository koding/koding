kd                          = require 'kd'
KDView                      = kd.View
ComputePlansModal           = require './computeplansmodal'
ComputePlansModalFooterLink = require './computeplansmodalfooterlink'


module.exports = class ComputePlansModalFree extends ComputePlansModal

  constructor: (options = {}, data) ->

    options.cssClass = 'free-plan'
    options.height   = 80
    super options, data


  viewAppended: ->

    @addSubView new KDView
      cssClass     : 'message'
      partial      : {
        'free'     : 'Free users are restricted to one VM.<br/>'
        'hobbyist' : 'Hobbyist plan is restricted to only one VM. <br/>'
      }[@getOption 'plan']
