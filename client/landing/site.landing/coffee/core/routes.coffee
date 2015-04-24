do ->

  getAction = (formName) -> switch formName
    when 'login'    then 'log in'
    when 'register' then 'register'

  handleRoot = ->
    # don't load the root content when we're just consuming a hash fragment
    return if location.hash.length

    { router } = KD.singletons
    groupName  = KD.utils.getGroupNameFromLocation()

    if groupName is 'koding'
    then router.openSection 'Home'
    else router.openSection 'TeamLanding'



  KD.registerRoutes 'Core',
    '/' : handleRoot
    ''  : handleRoot
