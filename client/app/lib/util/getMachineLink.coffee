module.exports = (machine, workspace) ->

  workspaceSlug = if slug = workspace?.get 'slug' then slug else ''

  switch machine.get 'type'
    when 'own'
      return "/IDE/#{machine.get('slug') or machine.get('label')}/#{workspaceSlug}"
    when 'collaboration'
      return "/IDE/#{workspace.get 'channelId'}"
    when 'shared', 'reassigned'
      return "/IDE/#{machine.get 'uid'}/#{workspaceSlug}"
