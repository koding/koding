
class ComputePlansModal extends KDModalView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'computeplan-modal', options.cssClass
    options.width   ?= 336
    options.height  ?= 134
    options.overlay ?= yes

    super options


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


class ComputePlansModal.Free extends ComputePlansModal

  constructor:(options = {}, data)->

    super
      cssClass : 'free-plan'
      message  : options.message ? "Free users are restricted to one VM"

  viewAppended:->

    @addSubView new KDView
      cssClass : 'message'
      partial  : @getOption 'message'

    @addSubView new KDView
      cssClass : 'cp-footer'
      partial  : "Upgrade your account for more VMs RAM and Storage"
      click    : =>
        KD.singletons.router.handleRoute "/Pricing"
        @destroy()
