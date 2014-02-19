class PermissionsForm extends KDFormViewWithFields

  # TODO: this class is a bit of a mess.  I did some light refactoring, but
  # I decided that at least some of the concerns I have with this file are
  # dependent upon a cleaner intermediate data structure in the form api.

  constructor:(options,data)->

    group                   = data # @getData()
    {privacy,permissionSet} = options #@getOptions()

    roles = (role.title for role in options.roles when role.title isnt 'owner')

    addRoleDialog = null
    options.buttons or=
      Save          :
        style       : "solid green"
        loader      :
          color     : "#444444"
          diameter  : 12
        callback    : =>

          group.updatePermissions @reducedList(), (err,res)=>
            @buttons["Save"].hideLoader()
            unless err
              new KDNotificationView
                title : "Group permissions have been updated."
            KD.showError err

    options.fields or= optionizePermissions roles, permissionSet
    super options,data
    @setClass 'permissions-form col-'+roles.length

  readableText = (text)->
    dictionary =
      "JTag"        : "Tags"
      "JNewApp"        : "Apps"
      "JGroup"      : "Groups"
      "JPost"       : "Posts"
      "JVM"         : "Compute"
      "CActivity"   : "Activity"
      "JGroupBundle": "Group Bundles"
      "JDomain"     : "Domains"
      "JProxyFilter": "Proxy Filters"
      "JInvitation" : "Invitations"
      "JComments"   : "Comments"
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

  cascadeFormElements = (set,roles,module,permission)->
    [current,remainder...] = roles
    cascadeData = {}

    isChecked = checkForPermission set.permissions, module, permission, current

    cssClass = 'permission-switch '+__utils.slugify(permission)+' '+current

    name = _getCheckboxName module, permission, current

    cascadeData[current]= {
      name
      cssClass
      size         : "tiny"
      itemClass    : KodingSwitch
      defaultValue : isChecked ? no
    }

    if current in ['admin','owner']
      cascadeData[current].defaultValue = yes
      cascadeData[current].disabled = yes
    if current and remainder.length > 0
      cascadeData[current].nextElement = cascadeFormElements set, remainder, module, permission
    return cascadeData

  cascadeHeaderElements = (roles)->
    [current,remainder...] = roles
    cascadeData = {}
    cascadeData[current]=
      itemClass     : KDView
      partial       : readableText current
      cssClass      : 'text header-item role-'+__utils.slugify(current)
      attributes    :
        title       : readableText current
    if current and remainder.length > 0
      cascadeData[current].nextElement = cascadeHeaderElements remainder
    return cascadeData

  optionizePermissions = (roles, set)->
    permissionOptions =
      head              :
        itemClass       : KDView
        cssClass        : 'permissions-header col-'+roles.length
        nextElement :
          cascadeHeaderElements roles

    for own module, permissions of set.permissionsByModule
      permissionOptions['header '+module.toLowerCase()] =
        itemClass       : KDView
        partial         : readableText module
        cssClass        : 'permissions-module text'

      for permission in permissions
        permissionOptions[module+'-'+__utils.slugify(permission)] =
          itemClass     : KDView
          partial       : readableText permission
          cssClass      : 'text'
          attributes    :
            title       : readableText permission
          nextElement :
            cascadeFormElements set, roles, module, permission
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

  viewAppended:->
    super
    # @applyScrollShadow()
