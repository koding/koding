class GroupsMemberRolesEditView extends JView

  constructor:(options = {}, data)->

    super

    @loader   = new KDLoaderView
      size    :
        width : 22

  setRoles:(editorsRoles, allRoles)->
    allRoles = allRoles.reduce (acc, role)->
      acc.push role.title  unless role.title in ['owner', 'guest']
      return acc
    , []

    @roles      = {
      usersRole    : @getDelegate().usersRole
      allRoles
      editorsRoles
    }

  setMember:(@member)->

  getSelectedRoles:->
    [@radioGroup.getValue()]

  addViews:->

    @loader.hide()

    isMe = KD.whoami().getId() is @member.getId()

    @radioGroup = new KDInputRadioGroup
      name          : 'user-role'
      defaultValue  : @roles.usersRole
      radios        : @roles.allRoles.map (role)->
        value       : role
        title       : role.capitalize()
      disabled      : isMe

    @addSubView @radioGroup, '.radios'

    @addSubView (new KDButtonView
      title    : "Make Owner"
      cssClass : 'modal-clean-gray'
      callback : -> log "Transfer Ownership"
      disabled : isMe
    ), '.buttons'

    @addSubView (new KDButtonView
      title    : "Kick"
      cssClass : 'modal-clean-red'
      callback : -> log "Kick user"
      disabled : isMe
    ), '.buttons'

    @$('.buttons').removeClass 'hidden'


  pistachio:->
    """
    {{> @loader}}
    <div class='radios'/>
    <div class='buttons hidden'/>
    """

  viewAppended:->

    super

    @loader.show()