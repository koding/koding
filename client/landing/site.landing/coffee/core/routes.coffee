do ->

  checkIfGroupExists = (groupName, callback) ->

    $.ajax
      url     : "/-/teams/#{groupName}"
      type    : 'post'
      success : (group) -> callback null, group
      error   : (err) -> callback err

  getAction = (formName) -> switch formName
    when 'login'    then 'log in'
    when 'register' then 'register'

  handleRoot = ->
    # don't load the root content when we're just consuming a hash fragment
    return if location.hash.length

    { router } = KD.singletons
    groupName  = KD.utils.getGroupNameFromLocation()

    return router.openSection 'Home'  if groupName is 'koding'

    checkIfGroupExists groupName, (err, group) ->
      if err or not group
        location.replace 'http://' + location.host.replace("#{groupName}.", '') + "/Teams?group=#{groupName}"
      else
        KD.config.group = group
        router.openSection 'Team'


  KD.registerRoutes 'Core',
    '/' : handleRoot
    ''  : handleRoot
