# not in use!!!

class RemovalView extends KDView

  constructor:(options={}, data)->
    super options, data

    {domain} = @getData()

    @addSubView new KDButtonView
      title    : "Remove #{domain}"
      cssClass : "clean-red"
      # callback : -> alert "Removed!" if confirm "Are you sure?"
      callback : => @confirmDeletion()
  
  confirmDeletion: ->
    modal = new KDModalView
      title        : "Are you sure?"
      overlay      : yes
      content      : "<div class='modalformline'>This will remove the domain <b>#{@getData().domain}</b> permanently, there is no way back!</div>"
      buttons      : 
        Remove     :
          cssClass : "modal-clean-red"
          callback : => log 'Remove domain', @getData()
        cancel     :
          cssClass : "modal-cancel"
          callback : -> modal.cancel()
