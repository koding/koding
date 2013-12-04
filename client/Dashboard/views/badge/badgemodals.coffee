class NewBadgeForm extends JView

  constructor:(options = {}, data)->

    @badgeForm                = new KDModalViewWithForms
      title                   : "Add New Badge"
      overlay                 : "yes"
      width                   : 600
      height                  : "auto"
      tabs                    :
        callback              : (formData)=> @createBadgeAndAssign formData
        navigable             : yes
        forms                 :
          "New Badge"         :
            buttons           :
              Add             :
                title         : "Add"
                style         : "modal-clean-green"
                type          : "submit"
              Cancel          :
                title         : "Cancel"
                style         : "modal-clean-red"
            fields            :
              Title           :
                label         : "Title"
                type          : "text"
                name          : "title"
                placeholder   : "enter the name of the badge"
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "add badge name"
              Icon            :
                label         : "Badge Icon"
                type          : "text"
                name          : "iconURL"
                placeholder   : "enter the path of badge"
              Description     :
                label         : "Description"
                type          : "text"
                name          : "description"
                placeholder   : "Description of the badge to be showed to user"
              Permission      :
                label         : "Permission"
                itemClass     : KDSelectBox
                name          : "permission"
                selectOptions : [
                    { title : "No Permission", value : "none"   }
                  ]
          "Rules"             :
            fields            : {}

    super options, data

    @updateRulesTabView()
    @updatePermissionBoxData()

  pistachio:->
    """
    {{> @badgeForm}}
    """

  updatePermissionBoxData:->
    selectRoles = []
    permissionBox = @badgeForm.modalTabs.forms["New Badge"].inputs.Permission
    currentGroup  = KD.getSingleton("groupsController").getCurrentGroup()
    currentGroup.fetchRoles (err, roles)=>
      for role in roles
        selectRoles.push title : role.title, value : role._id
      permissionBox.setSelectOptions selectRoles

  updateRulesTabView:->
    parentView = @badgeForm.modalTabs.forms["Rules"]
    parentView.addSubView new BadgeRules

  createBadgeAndAssign: (formData)->
    KD.remote.api.JBadge.create formData, (err, badge)=>
      badge.assignBadgeBatch formData.ids, (err) =>
        return err if err


class BadgeUpdateForm extends JView
  constructor:(options = {}, data)->
    {@badge} = data
    @badgeForm                = new KDModalViewWithForms
      title                   : "Modify Badge"
      overlay                 : "yes"
      width                   : 600
      height                  : "auto"
      tabs                    :
        goToNextFormOnSubmit  : no
        navigable             : yes
        forms                 :
          "Properties"        :
            callback          : (formData)=>
              @badge.modify formData, (err, badge)->
                return err if err
                new KDNotificationView
                  title       : "Badge Updated !"
                  duration    : 1000
            buttons           :
              Add             :
                title         : "Save"
                style         : "modal-clean-green"
                type          : "submit"
            fields            :
              Title           :
                label         : "Title"
                type          : "text"
                name          : "title"
                defaultValue  : @badge.title
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "add badge name"
              Icon            :
                label         : "Badge Icon"
                type          : "text"
                name          : "iconURL"
                defaultValue  : @badge.iconURL
              Description     :
                label         : "Description"
                type          : "text"
                name          : "description"
                defaultValue  : @badge.description
              Permission      :
                label         : "Permission"
                itemClass     : KDSelectBox
                name          : "permission"
                selectOptions : [
                    { title : "No Permission", value : "none"   }
                  ]
          "Delete"            :
            fields            :
              Approval        :
                title         : ""
                label         : "Why so serious?"
                itemClass     : KDLabelView
            buttons           :
              Remove          :
                label         : ""
                title         : "Remove"
                style         : "modal-clean-red"
                callback      : (formData)=>
                  modal = new BadgeRemoveForm {}, {@badge}
                  modal.setDelegate this
          "Rules"             :
            fields            : {}
    @updatePermissionBoxData()
    # create rules tab
    @updateRulesTabView()
    super options, data

  updatePermissionBoxData:->
    selectRoles = []
    permissionBox = @badgeForm.modalTabs.forms["Properties"].inputs.Permission
    currentGroup  = KD.getSingleton("groupsController").getCurrentGroup()
    currentGroup.fetchRoles (err, roles)=>
      for role in roles
        selectRoles.push title : role.title, value : role._id
      permissionBox.setSelectOptions selectRoles

  updateRulesTabView: ->
    parentView = @badgeForm.modalTabs.forms["Rules"]
    parentView.addSubView new BadgeRules badge : @badge


class BadgeRemoveForm extends KDModalViewWithForms
  constructor:(options = {}, data)->
    options.title           or= 'Sure ?'
    options.tabs            ?=
      forms                 :
        deleteForm          :
          buttons           :
            yes             :
              title         : "YES"
              style         : "modal-clean-green"
              type          : "submit"
              callback      : =>
                {badge} = @getData()
                badge.deleteBadge (err)=>
                  return err if err
                  @destroy()
                  @getDelegate().destroy()
                  @getDelegate().getOptions().itemList.destroy()
            Cancel          :
              title         : "No"
              style         : "modal-clean-red"
              type          : "cancel"
              callback      : =>
                @destroy()

    super options, data
