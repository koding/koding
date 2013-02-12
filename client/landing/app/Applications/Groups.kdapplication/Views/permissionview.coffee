class GroupPermissionsView extends JView

  constructor:->

    super

    @setClass "permissions-view"

    group = @getData()

    @permissionsLoader = new KDLoaderView
      size          :
        width       : 32

    addPermissionsView = (newPermissions)=>
      group.fetchRoles (err,roles)=>
        group.fetchPermissions (err, permissionSet)=>
          @permissionsLoader.hide()
          unless err
            if newPermissions
              permissionSet.permissions = newPermissions
            if @permissions then @removeSubView @permissions
            @addSubView @permissions = new PermissionsModal {
              privacy: group.privacy
              permissionSet
              roles
            }, group
            @permissions.emit 'RoleViewRefreshed'
            @permissions.on 'RoleWasAdded', (newPermissions,role,copy)=>
              copiedPermissions = []
              for permission of newPermissions
                if newPermissions[permission].role is copy
                  copiedPermissions.push
                    module : newPermissions[permission].module
                    permissions : newPermissions[permission].permissions
                    role : role
              for item in copiedPermissions
                newPermissions.push item
              addPermissionsView(newPermissions)
              # @render()
          else
            forms['Permissions'].addSubView new KDView
              partial : 'No access'

    @permissionsLoader.show()
    addPermissionsView()

  viewAppended:->
    super
    @permissionsLoader.show()


  pistachio:->
    """
    {{> @permissionsLoader}}
    """
