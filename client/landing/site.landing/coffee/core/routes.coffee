do ->

  getAction = (formName) -> switch formName
    when 'login'    then 'log in'
    when 'register' then 'register'

  handleRoot = ->
    # don't load the root content when we're just consuming a hash fragment
    return if location.hash.length

    { router }           = KD.singletons
    { groupName, group } = KD.config

    return router.openSection 'Home'  if groupName is 'koding'

    unless group
      location.replace 'http://' + location.host.replace("#{groupName}.", '') + "/Teams?group=#{groupName}"
    else
      router.openSection 'Team'


  KD.registerRoutes 'Core',
    '/' : handleRoot
    ''  : handleRoot
