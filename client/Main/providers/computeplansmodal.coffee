class ComputePlansModal extends KDModalView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'computeplan-modal', options.cssClass
    options.width   ?= 336
    options.overlay ?= yes

    super options
