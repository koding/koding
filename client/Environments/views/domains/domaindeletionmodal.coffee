class DomainDeletionModal extends KDModalView

  constructor: (options = {}, data) ->

    options.title        or= "Are you sure?"
    options.overlay       ?= yes
    options.overlayClick  ?= no
    options.cssClass       = KD.utils.curry 'env-deletion-modal', options.cssClass
    options.content      or= "<div class='modalformline'>This will remove the domain <b>#{data.domain}</b> permanently, there is no way back!</div>"
    options.deleteMesage or= "<b>#{data.domain}</b> has been removed."
    options.buttons      or=
      "Remove"   :
        cssClass : "modal-clean-red"
        callback : =>
          domain = @getData()
          domain.remove (err)=>
            return KD.showError err  if err
            @emit "domainRemoved"
            @destroy()
            new KDNotificationView
              title    : options.deleteMesage
              type     : "mini"
              cssClass : "success"
              duration : 5000

      "Keep it"  :
        cssClass : "modal-clean-green"
        callback : => @cancel()

    super options, data

    removeButton = this.buttons.Remove
    removeButton.$().blur()
