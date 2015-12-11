module.exports = (machine, workspace) ->

  switch machine.get 'type'
    when 'own'
      return "/IDE/#{machine.get('slug') or machine.get('label')}/#{workspace?.get 'slug'}"
    when 'collaboration'
      return "/IDE/#{workspace.get 'channelId'}"
    when 'shared', 'reassigned'
      return "/IDE/#{machine.get 'uid'}"
