class ComputePlansModal.Loading extends ComputePlansModal

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


