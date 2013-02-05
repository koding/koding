class PermissionsModal extends KDFormViewWithFields

  ['list','reducedList','tree'].forEach (method)=>
    @::[method] =-> @getPermissions method

  constructor:(options,data)->

    group                   = data # @getData()
    {privacy,permissionSet} = options #@getOptions()

    # here we should handle custom roles and add them for display
    roles = ['member','moderator','admin']
    roles.unshift 'guest' if group.privacy is 'public'


    readableText = (text)->
      dictionary =
        "JTag" : "Tags"
        "JGroup": 'Groups'
        "JReview": 'Reviews'
        "JPost":'Posts'
        "JVocabulary": 'Vocabularies'
      return dictionary[text] or text.charAt(0).toUpperCase()+text.slice(1)

    _getCheckboxName =(module, permission, role)->
      ['permission', module].join('-')+'|'+[role, permission].join('|')

    checkForPermission = (permissions,module,permission,role)->
      for perm in permissions
        if perm.module is module and perm.role is role
          for perm1 in perm.permissions
            return yes  if perm1 is permission
          return no

    cascadeFormElements = (set,roles,module,permission)->
      [current,remainder...] = roles.slice()
      cascadeData = {}
      cascadeData[current]=
          itemClass     : KDCheckBox
          cssClass      : 'permission-checkbox '+__utils.slugify(permission)+' '+current
          name          : _getCheckboxName module, permission, current
          defaultValue  : checkForPermission set.permissions,module,permission,current
      if current is 'admin'
        cascadeData[current].defaultValue = yes
        cascadeData[current].disabled = yes
      if current and remainder.length > 0
        cascadeData[current].nextElementFlat = cascadeFormElements set, remainder, module, permission
      return cascadeData

    cascadeHeaderElements = (roles)->
      [current,remainder...] = roles.slice()
      cascadeData = {}
      cascadeData[current]=
          itemClass     : KDView
          partial       : readableText current
          cssClass      : 'text header-item role-'+__utils.slugify(current)
      if current and remainder.length > 0
        cascadeData[current].nextElementFlat = cascadeHeaderElements remainder
      return cascadeData

    optionizePermissions = (set)->
      permissionOptions =
        head              :
          itemClass       : KDView
          cssClass        : 'permissions-header col-'+roles.length
          nextElementFlat :
            cascadeHeaderElements roles

      for module, permissions of set.permissionsByModule
        permissionOptions['header '+module.toLowerCase()] =
          itemClass       : KDView
          partial         : readableText module
          cssClass        : 'permissions-module text'

        for permission in permissions
          permissionOptions[module+'-'+__utils.slugify(permission)] =
            itemClass     : KDView
            partial       : readableText permission
            cssClass      : 'text'
            tooltip       :
              title       : readableText permission
              direction   : 'center'
              placement   : 'left'
              offset      :
                top       : 3
                left      : 0
              showOnlyWhenOverflowing : yes
            nextElementFlat :
              cascadeFormElements set, roles, module, permission
      permissionOptions

    options.buttons or= 
        Save          :
          style       : "modal-clean-gray"
          loader      :
            color     : "#444444"
            diameter  : 12
          callback    : =>
            group.updatePermissions(
              @reducedList()
              (err,res)=>
                log 'updated permissions',err,res
                @buttons["Save"].hideLoader()
                # TODO: do something with this callback
            )
    options.fields or= optionizePermissions permissionSet
    super options,data
    @setClass 'permissions-form col-'+roles.length

    @bindEvent 'scroll'

    @on 'scroll', (event={})=>
      @applyScrollShadow event

  applyScrollShadow:(event)->
    isAtTop = @$().scrollTop() is 0 
    isAtBottom = @$().scrollTop()+@getHeight() is @$()[0].scrollHeight

    unless isAtTop
      @$('.permissions-header').addClass 'scrolling'
    else
      @$('.permissions-header').remove 'scrolling'
  
    unless isAtBottom 
      @$('.formline.button-field').addClass 'scrolling'
    else
      @$('.formline.button-field').removeClass 'scrolling'


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
      storageKey = module+':'+role
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

  getPermissions:(structure='reducedList')->
    values = @getFormValues()
    switch structure
      when 'reducedList'  then return createReducedList values
      when 'list'         then return values
      when 'tree'         then return createTree values
      else throw new Error "Unknown structure #{structure}"

  viewAppended:->
    super
    @applyScrollShadow()
 