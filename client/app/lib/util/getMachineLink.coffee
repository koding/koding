module.exports = (machine, workspace) ->

  workspaceSlug = if slug = workspace?.get 'slug' then slug else ''

  switch machine.get 'type'
    when 'own'
      return "/IDE/#{machine.get('slug') or machine.get('label')}/"
    when 'collaboration'

      workspaces = machine.get('workspaces').toJS()
      workspace  = workspaces[(Object.keys workspaces).first]

      return "/IDE/#{workspace.channelId}"
    when 'shared', 'reassigned'
      return "/IDE/#{machine.get 'uid'}/#{workspaceSlug}"
