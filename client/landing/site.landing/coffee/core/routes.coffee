do ->

  getAction = (formName) -> switch formName
    when 'login'    then 'log in'
    when 'register' then 'register'

  handleRoot = (options)->
    # don't load the root content when we're just consuming a hash fragment
    return if location.hash.length

    { router }           = KD.singletons
    { groupName, group } = KD.config

    if groupName is 'koding'
      return router.openSection 'Home', null, null, (app)->
        app.handleQuery options

    if not group or KD.config.environment is 'production'
      location.replace 'http://' + location.host.replace("#{groupName}.", '') + "/Teams?group=#{groupName}"
    else
      router.openSection 'Team', null, null, (app) -> app.jumpTo 'login'


  KD.registerRoutes 'Core',
    '/' : handleRoot
    ''  : handleRoot
