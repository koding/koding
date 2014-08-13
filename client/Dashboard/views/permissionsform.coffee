class PermissionsForm extends KDFormViewWithFields

  # TODO: this class is a bit of a mess.  I did some light refactoring, but
  # I decided that at least some of the concerns I have with this file are
  # dependent upon a cleaner intermediate data structure in the form api.

  constructor:(options,data)->

    @group           = data
    {@permissionSet} = options

    @roles = (role.title for role in options.roles when role.title isnt 'owner')
    options.buttons or=
      Save          :
        style       : "solid medium green"
        loader      : yes
        callback    : =>
          @buttons["Save"].hideLoader()
          @group.updatePermissions @reducedList(), (err,res)=>
            @buttons["Save"].hideLoader()
            return KD.showError err if err
            new KDNotificationView title: "Group permissions have been updated."
      Add           :
        title       : "Add"
        style       : "solid medium green"
        callback    : @bound "showNewRoleModal"

    options.fields or= optionizePermissions @roles, @permissionSet
    super options,data
    @setClass 'permissions-form col-'+@roles.length

  showNewRoleModal:->
    roleSelectOptions = []
    @selectRoleModal  = new KDModalView title: "Select Role to Copy", overlay: yes
    roleSelectOptions.push {title: role, value: role} for role in @roles

    roleNameLabel   = new KDLabelView title: "Role name"
    @roleName       = new KDInputView
      name          : "rolename"
      placeholder   : "role name..."

    roleSelectLabel = new KDLabelView title: "Select role to copy from"
    @roleSelectBox   = new KDSelectBox
      name          : "roletocopy"
      selectOptions : roleSelectOptions

    confirmButton   = new KDButtonView
      title         : "Select"
      callback      : =>
        titleOfRole = @roleName.getValue()
        unless titleOfRole
          @roleName.setClass "kdinput text validation-error"
        else
          @group.addCustomRole title: titleOfRole , (err, newRole)=>
            return KD.showError err if err
            duplicatedRole = @roleSelectBox.getValue()
            newPermissions = @getPermissionsOfRole duplicatedRole
            currentPermissionSet = @reducedList()
            permission.role = titleOfRole for permission in newPermissions
            currentPermissionSet.push perm for perm in newPermissions
            @group.updatePermissions currentPermissionSet, (err,res)=>
              return KD.showError err if err
              @emit "RoleWasAdded", currentPermissionSet, newRole.title

    @selectRoleModal.addSubView roleNameLabel
    @selectRoleModal.addSubView @roleName
    @selectRoleModal.addSubView roleSelectLabel
    @selectRoleModal.addSubView @roleSelectBox
    @selectRoleModal.addSubView confirmButton

  readableText = (text)->
    dictionary =
      "JNewApp"        : "Apps"
      "JGroup"         : "Groups"
      "SocialMessage"  : "Social API"
      "JVM"            : "Compute"
      "JGroupBundle"   : "Group Bundles"
      "JDomain"        : "Domains"
      "JProxyFilter"   : "Proxy Filters"
      "JInvitation"    : "Invitations"
      "JStack"         : "Stacks"
      "JStackTemplate" : "Stack Templates"
      "JCredential"    : "Credentials"

    return dictionary[text] or text.charAt(0).toUpperCase()+text.slice(1)

  _getCheckboxName =(module, permission, role)->
    ['permission', module].join('-')+'|'+[role, permission].join('|')

  checkForPermission = (permissions,module,permission,role)->
    for perm in permissions
      if perm.module is module and perm.role is role
        for perm1 in perm.permissions
          if perm1? and perm1 is permission
            return yes
        return no

  cascadeFormElements = (set,roles,module,permission,roleCount=0)->

    [current,remainder...] = roles
    cascadeData = {}

    isChecked = checkForPermission set.permissions, module, permission, current

    cssClass = 'permission-switch tiny '+utils.slugify(permission)+' '+current

    name = _getCheckboxName module, permission, current

    widthForRows = (window.innerWidth - 754)/roleCount
    cascadeData[current]= {
      name
      cssClass
      itemClass    : PermissionSwitch
      defaultValue : isChecked ? no
      widthForRows
    }

    if current in ['admin','owner']
      cascadeData[current].defaultValue = yes
      cascadeData[current].disabled = yes
    if current and remainder.length > 0
      cascadeData[current].nextElement = cascadeFormElements set, remainder, module, permission, roleCount
    return cascadeData

  cascadeHeaderElements = (roles, roleCount)->
    widthForRows = (window.innerWidth - 754)/roleCount

    [current,remainder...] = roles
    cascadeData = {}
    cascadeData[current]=
      itemClass     : KDView
      partial       : readableText current
      cssClass      : 'text header-item role-'+utils.slugify(current)
      attributes    :
        title       : readableText current
        style       : "width : #{widthForRows}px"
    if current and remainder.length > 0
      cascadeData[current].nextElement = cascadeHeaderElements remainder, roleCount
    return cascadeData

  optionizePermissions = (roles, set)->
    permissionOptions =
      head            :
        itemClass     : KDView
        cssClass      : 'permissions-header col'
        nextElement   :
          cascadeHeaderElements roles, roles.length

    # set.permissionsByModule is giving all the possible permissions
    # module is collection name (JComment, JDomain etc..)
    # var permissions is permission under collection (module)
    # like "edit comments" for JComment
    for own module, permissions of set.permissionsByModule
      permissionOptions['header '+module.toLowerCase()] =
        itemClass       : KDView
        partial         : readableText module
        cssClass        : 'permissions-module text'

      for permission in permissions
        permissionOptions[module+'-'+utils.slugify(permission)] =
          itemClass     : KDView
          partial       : readableText permission
          cssClass      : 'text'
          attributes    :
            title       : readableText permission
          nextElement :
            cascadeFormElements set, roles, module, permission, roles.length
    permissionOptions

  createTree =(values)->
    values.reduce (acc, {module, role, permission})->
      acc[module] ?= {}
      acc[module][role] ?= []
      acc[module][role].push permission
      return acc
    , {}

  createReducedList =(values)->
    cache = {}
    values.reduce (acc, {module, role, permission})->
      storageKey = "#{module}:#{role}"
      cached = cache[storageKey]
      if cached?
        cached.permissions.push permission
      else
        cache[storageKey] = {module, role, permissions: [permission]}
        acc.push cache[storageKey]
      return acc
    , []

  getFormValues:->
    @$().serializeArray()
    .map ({name})->
      [facet, role, permission] = name.split '|'
      module = facet.split('-')[1]
      {module, role, permission}

  ['list','reducedList','tree'].forEach (method)=>
    @::[method] =-> @getPermissions method

  getPermissions:(structure='reducedList')->
    values = @getFormValues()
    switch structure
      when 'reducedList'  then return createReducedList values
      when 'list'         then return values
      when 'tree'         then return createTree values
      else throw new Error "Unknown structure #{structure}"

  getPermissionsOfRole: (role)->
    allValues = @list()
    selectedRoleValues = []
    selectedRoleValues.push permission for permission in allValues when permission.role is role
    createReducedList selectedRoleValues
