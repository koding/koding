kd = require 'kd'
KDModalView = kd.ModalView

module.exports = class ComputePlansModal extends KDModalView

  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry 'computeplan-modal env-modal', options.cssClass
    options.width   ?= 336
    options.overlay ?= yes

    super options
