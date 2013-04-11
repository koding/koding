class GroupsMemberRolesEditView extends JView

  constructor:(options = {}, data)->

    super

    @loader   = new KDLoaderView
      size    :
        width : 22

  setRoles:(editorsRoles, allRoles)->
    allRoles = allRoles.reduce (acc, role)->
      acc.push role.title  unless role.title in ['owner', 'guest', 'member']
      return acc
    , []

    @roles      = {
      usersRole    : @getDelegate().usersRole
      allRoles
      editorsRoles
    }

  setMember:(@member)->

  setGroup:(@group)->

  getSelectedRoles:->
    @checkboxGroup.getValue()

  addViews:->

    @loader.hide()

    isAdmin = 'admin' in @roles.usersRole
    @checkboxGroup = new KDInputCheckboxGroup
      name         : 'user-role'
      defaultValue : @roles.usersRole
      checkboxes   : @roles.allRoles.map (role)=>
        if role is 'admin'
          callback = =>
            isAdmin = 'admin' in @checkboxGroup.getValue()
            for el in @checkboxGroup.getInputElements()
              el = $(el)
              if el.val() isnt 'admin'
                if isAdmin
                  el.removeAttr 'checked'
                  el.parent().hide()
                else
                  el.parent().show()
        else
          callback = ->

        value      : role
        title      : role.capitalize()
        visible    : if role isnt 'admin' and isAdmin then no else yes
        callback   : callback

    @addSubView @checkboxGroup, '.checkboxes'

    if 'owner' in @roles.editorsRoles
      @addSubView (new KDButtonView
        title    : "Make Owner"
        cssClass : 'modal-clean-gray'
        callback : => @showTransferOwnershipModal()
      ), '.buttons'

    @addSubView (new KDButtonView
      title    : "Kick"
      cssClass : 'modal-clean-red'
      callback : => @showKickModal()
    ), '.buttons'

    @$('.buttons').removeClass 'hidden'

  showTransferOwnershipModal:->
    checkGroupSlug = (input, event, modal, showError)=>
      if input.getValue() is @group.slug
        input.setValidationResult 'slugCheck', null
        modal.modalTabs.forms.TransferOwnership.buttons['Transfer Ownership'].enable()
      else
        input.setValidationResult 'slugCheck', 'Sorry, entered value does not match group slug!', showError

    modal = new KDModalViewWithForms
      title                        : 'Transfer Ownership'
      content                      : '<div class="modalformline"><strong>Caution:</strong> Are you sure that you want to transfer the ownership to this user? This cannot be revoked! Please enter group slug into the field below to continue:</div>'
      overlay                      : yes
      width                        : 500
      height                       : 'auto'
      tabs                         :
        forms                      :
          TransferOwnership        :
            callback               : =>
              @group.transferOwnership @member.getId(), (err)=>
                return @showErrorMessage err if err
                modal.modalTabs.forms.TransferOwnership.buttons['Transfer Ownership'].hideLoader()
                modal.destroy()
            buttons                :
              'Transfer Ownership' :
                style              : 'modal-clean-red'
                type               : 'submit'
                disabled           : yes
                loader             :
                  color            : '#ffffff'
                  diameter         : 15
                callback           : -> @showLoader()
              Cancel               :
                style              : 'modal-cancel'
                callback           : (event)-> modal.destroy()
            fields                 :
              groupSlug            :
                label              : 'Confirm'
                itemClass          : KDInputView
                placeholder        : "Enter '#{@group.slug}' to confirm..."
                validate           :
                  rules            :
                    required       : yes
                    slugCheck      : (input, event) -> checkGroupSlug input, event, modal, no
                    finalCheck     : (input, event) -> checkGroupSlug input, event, modal, yes
                  messages         :
                    required       : 'Please enter group slug'
                  events           :
                    required       : 'blur'
                    slugCheck      : 'keyup'
                    finalCheck     : 'blur'

  showKickModal:->
    modal = new KDModalView
        title          : 'Kick Member'
        content        : "<div class='modalformline'>Are you sure you want to kick this member?</div>"
        height         : 'auto'
        overlay        : yes
        buttons        :
          Kick         :
            style      : "modal-clean-red"
            loader     :
              color    : "#ffffff"
              diameter : 16
            callback   : =>
              @group.kickMember @member.getId(), (err)=>
                return @showErrorMessage err if err
                @getDelegate().destroy()
                modal.buttons.Kick.hideLoader()
                modal.destroy()
          Cancel       :
            style      : "modal-cancel"
            callback   : (event)-> modal.destroy()

  showErrorMessage:(err)->
    warn err
    new KDNotificationView 
      title    : if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
      duration : 2000

  pistachio:->
    """
    {{> @loader}}
    <div class='checkboxes'/>
    <div class='buttons hidden'/>
    """

  viewAppended:->

    super

    @loader.show()