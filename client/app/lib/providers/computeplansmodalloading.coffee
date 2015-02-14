kd = require 'kd'
KDLoaderView = kd.LoaderView
ComputePlansModal = require './computeplansmodal'


module.exports = class ComputePlansModalLoading extends ComputePlansModal

  constructor:(options = {}, data)->

    super
      cssClass    : 'loading'
      overlay     : no
      cancellable : no


  viewAppended:->

    @addSubView new KDLoaderView
      showLoader : yes
      size       :
        width    : 40
        height   : 40
