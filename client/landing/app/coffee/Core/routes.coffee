do ->

  getAction = (formName) -> switch formName
    when 'login'    then 'log in'
    when 'register' then 'register'

  handleRoot = ->
    # don't load the root content when we're just consuming a hash fragment
    unless location.hash.length

      {router} = KD.singletons
      {entryPoint}      = KD.config
      replaceState      = yes

      router.handleRoute router.getDefaultRoute(), {entryPoint}


  KD.registerRoutes 'Core',
    '/'                      : handleRoot
    ''                       : handleRoot
