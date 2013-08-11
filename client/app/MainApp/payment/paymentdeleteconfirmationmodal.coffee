class PaymentDeleteConfirmationModal extends KDModalView

  constructor:(options={}, data)->
    subscription = options.subscription

    if data.status is 'canceled'
      content = """<p>Removing this VM will <b>destroy</b> all the data in
                   this VM including all other users in filesystem. <b>Please
                   be careful this process cannot be undone.</b></p>

                   <p>Do you want to continue?</p>"""
    else
      if options.type isnt 'expensed'
        pauseWarning = """<p>You can 'pause' your plan instead, and continue using it
                          until #{dateFormat subscription.renew }.</p>"""
      else
        pauseWarning = ''

      content = """<p>Removing this VM will <b>destroy</b> all the data in
                   this VM including all other users in filesystem. <b>Please
                   be careful this process cannot be undone.</b></p>
                   #{pauseWarning}
                   <p>What do you want to do?</p>"""

    options.title    or= 'Confirm VM Deletion'
    options.content  or= "<div class='modalformline'>#{content}</div>"
    options.cssClass or= 'vm-delete'
    options.overlay   ?= yes
    options.buttons  or=
      No          :
        title     : 'Cancel'
        cssClass  : 'modal-clean-gray'
        callback  : =>
          @destroy()
          options.callback? no
      Pause       :
        title     : 'Pause Plan'
        cssClass  : 'modal-clean-green hidden'
        callback  : =>
          data.cancel =>
            @destroy()
            options.callback? no
      Delete      :
        title     : 'Delete VM'
        cssClass  : 'modal-clean-red'
        callback  : =>
          @destroy()
          options.callback? yes

    super options, data

    if @getData().status isnt 'canceled' and options.type isnt 'expensed'
      @buttons.Pause.show()
