kd            = require 'kd'
KDModalView   = kd.ModalView
applyMarkdown = require 'app/util/applyMarkdown'


module.exports = class StackTemplateReadmeModal extends KDModalView


  constructor: (options = {}, data) ->

    options.cssClass        or= 'has-markdown'
    options.title           or= data.title
    options.content         or= applyMarkdown data.description
    options.width           or= 600
    options.overlay          ?= yes
    options.overlayClick     ?= yes
    options.overlayOptions  or=
      cssClass                : 'second-overlay'

    super options, data
