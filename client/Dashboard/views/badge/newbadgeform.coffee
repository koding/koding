class NewBadgeForm extends KDView

  constructor:(options = {}, data)->
    super options, data

    @badgeForm                = new KDModalViewWithForms
      title                   : "Add New Badge"
      overlay                 : yes
      cssClass                : "add-badge-modal"
      width                   : 600
      tabs                    :
        callback              : (formData)=> @createBadgeAndAssign formData
        navigable             : no
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
                name          : "title"
                placeholder   : "enter the name of the badge"
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "add badge name"
              Icon            :
                label         : "Badge Icon"
                name          : "iconURL"
                placeholder   : "enter the path of badge"
              Description     :
                label         : "Description"
                name          : "description"
                placeholder   : "Description of the badge to be showed to user"
              Permission      :
                label         : "Permission"
                itemClass     : KDSelectBox
                name          : "role"
                defaultValue  : "none"
                selectOptions : [{title : "No Permission", value : "none"}]
          "Rules"             :
            fields            : {}

    @updateRulesTabView()
    @updatePermissionBoxData()

  viewAppended:->
    @addSubView @badgeForm

  updatePermissionBoxData:->

    selectRoles   = []
    permissionBox = @badgeForm.modalTabs.forms["New Badge"].inputs.Permission
    currentGroup  = KD.getSingleton("groupsController").getCurrentGroup()
    currentGroup.fetchRoles (err, roles) ->
      tmpRoles = ["admin", "owner", "moderator", "guest", "member"]
      selectRoles = {title, value} for {title, value} in roles when not title in tmpRoles
      permissionBox.setSelectOptions selectRoles

  updateRulesTabView:->
    parentView = @badgeForm.modalTabs.forms["Rules"]
    @badgeRules = new BadgeRules
    parentView.addSubView @badgeRules

  createBadgeAndAssign: (formData)->
    KD.remote.api.JBadge.create formData, (err, badge)=>
      if err
        new KDNotificationView title : err.message
      else
        {badgeListController} = @getOptions()
        badgeListController.addItem badge
        @badgeRules.emit "BadgeCreated"
        idArray = formData.ids.split ","
        badge.assignBadgeBatch idArray, (err) ->
          return err if err
