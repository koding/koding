class GroupPermissionsView extends JView

  constructor:->

    super

    @setClass "permissions-view"

    group = @getData()

    @loader           = new KDLoaderView
      cssClass        : 'loader'
    @loaderText       = new KDView
      partial         : 'Loading Permissions...'
      cssClass        : ' loader-text'

    addPermissionsView = (newPermissions)=>
      group.fetchRoles (err,roles)=>
        group.fetchPermissions (err, permissionSet)=>
          @loader.hide()
          @loaderText.hide()
          unless err
            if newPermissions
              permissionSet.permissions = newPermissions

            @permissions.destroy() if @permissions

            @addSubView @permissions = new PermissionsModal {
              privacy: group.privacy
              permissionSet
              roles
              delegate : @
            }, group

            @permissions.emit 'RoleViewRefreshed'
            @permissions.on 'RoleWasAdded', (newPermissions,role,copy)=>
              copiedPermissions = []
              for permission of newPermissions
                if newPermissions[permission].role is copy
                  copiedPermissions.push
                    module      : newPermissions[permission].module
                    permissions : newPermissions[permission].permissions
                    role        : role
              for item in copiedPermissions
                newPermissions.push item
              addPermissionsView(newPermissions)
              @permissions.emit 'RoleViewRefreshed'

          else
            @addSubView new KDView
              partial : 'No access'

    @loader.show()
    @loaderText.show()
    addPermissionsView()

  viewAppended:->
    super
    @loader.show()
    @loaderText.show()

  pistachio:->
    """
    {{> @loader}}
    {{> @loaderText}}
    """
