class GroupsLandingPageLoginLink extends CustomLinkView

  constructor:(options, data)->
    {groupEntryPoint} = options
    options.baseHref = "/#{groupEntryPoint}"
    options.title ?= ' '
    super

  click:(event)->
    event.preventDefault()
    options = @getOptions()
    @emit 'LoginLinkRedirect',
      href              : options.attributes.href
      groupEntryPoint   : options.groupEntryPoint
      section           : options.section

  setState:(@state)->
    data = @getData()
    options = @getOptions()
    if state.isMember
      data.title = 'Go to group'
      options.attributes.href = "#{options.baseHref}/Activity"
      options.section = 'Activity'
    else if state.approvalEnabled or not state.isLoggedIn
      data.title = 'Request access'
      options.section = 'Join'
      options.attributes.href = "#{options.baseHref}/Join"
    else
      data.title = 'Return to Koding'
      options.attributes.href = 'https://koding.com'
    @template.update()
    @getDomElement().attr 'href', options.attributes.href
