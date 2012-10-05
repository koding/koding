class PermissionsGrid extends KDView
  _getCheckbox =(module, permission, role)->
    name = ['permission', module].join('-')+'|'+[role, permission].join('|')
    """
    <input type=checkbox name='#{name}'#{
      if role is 'admin' then ' disabled checked' else ''
    }>
    """

  viewAppended:->
    @setPartial @partial()

  getPermissions:->
    @$('form')
      .serializeArray()
      .map ({name})->
        [facet, role, permission] = name.split '|'
        module = facet.split('-')[1]
        {
          module
          role
          permission
        }
      .reduce (acc, {module, role, permission})->
        acc[module] ?= {}
        acc[module][role] ?= []
        acc[module][role].push permission
        acc
      , {}

  partial:->
    {permissionSet, privacy} = @getOptions()
    partial =
      """
      <form><table class="permissions-grid">
        <thead><tr>
          <th></th>
      """
    if privacy is 'public' then partial +=
      """
          <th>guest</th>
      """
    partial +=
      """
          <th>member</th><th>moderator</th><th>admin</th>
        </tr></thead>
        <tbody>
      """
    for own module, permissions of permissionSet.permissionsByModule
      partial +=
        """
            <tr>
              <td class="module" colspan=#{
                if privacy is 'public' then '5' else '4'
              }><strong>#{module}</strong></td>
            </tr>
        """
      for permission in permissions
        partial +=
          """
              <tr>
                <td class="permission">#{permission}</td>
          """
        if privacy is 'public' then partial +=
          """
                <td>#{_getCheckbox module, permission, 'guest'}</td>
          """
        partial +=
          """
                <td>#{_getCheckbox module, permission, 'member'}</td>
                <td>#{_getCheckbox module, permission, 'moderator'}</td>
                <td>#{_getCheckbox module, permission, 'admin'}</td>
              </tr>
          """
    partial +=
      """
        </tbody>
      </table></form>
      """
    partial