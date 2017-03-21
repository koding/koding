module.exports = getMachineLink = (machine) ->

  switch machine.get 'type'
    when 'own'
      return "/IDE/#{machine.get('slug') or machine.get('label')}/"
    when 'collaboration'
      return "/IDE/#{machine.get 'uid'}"
    when 'shared', 'reassigned'
      return "/IDE/#{machine.get 'uid'}"
