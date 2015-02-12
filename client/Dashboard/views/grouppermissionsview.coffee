class GroupPermissionsView extends JView

  constructor: (options={}, data)->
    options.cssClass = "permissions-view"
    super options, data

    @loader     = new KDLoaderView
      showLoader     : yes
      loaderOptions  :
        shape        : 'spiral'
        color        : '#a4a4a4'
      size           :
        width        : 40
        height       : 40

    @addPermissionsView()

  addPermissionsView: ->
    group = @getData()
    group.fetchRoles (err,roles)=>
      return KD.showError err if err
      group.fetchPermissions (err, permissionSet)=>
        return KD.showError err if err
        @addSubView permissions = new PermissionsForm {permissionSet,roles}, group
        permissions.on 'RoleWasAdded', (newPermissions,role)=>
          permissions.destroy()
          @addPermissionsView()
          @loader.show()

        @loader.hide()

  pistachio:->
    """
    {{> @loader}}
    """
