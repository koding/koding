class DomainDeletionModal extends KDModalView

  constructor:(options={}, data)->
    options.title        or= "Are you sure?"
    options.overlay       ?= yes
    options.overlayClick  ?= no
    options.content      or= "<div class='modalformline'>This will remove the domain <b>#{data.domain}</b> permanently, there is no way back!</div>"
    options.buttons      or=
      "Remove"   :
        cssClass : "modal-clean-red"
        callback : =>
          domain = @getData()
          domain.remove (err)=>
            return KD.showError err  if err
            new KDNotificationView {title:"<b>#{data.domain}</b> has been removed."}
            @emit "domainRemoved"
            @destroy()

      "Keep it"  :
        cssClass : "modal-clean-green"
        callback : => @cancel()

    super options, data

    removeButton = this.buttons.Remove
    removeButton.$().blur()