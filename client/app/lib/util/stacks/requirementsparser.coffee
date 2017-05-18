module.exports = requirementsParser = (content) ->

  content = content.replace /#.+/igm, ''

  allowedProps =
    user       : ['username', 'email'] # JUser
    account    : ['profile']           # JAccount
    group      : ['title', 'slug']     # JGroup
  # Following injected by Kloud ~ GG
  # stack      : ['id']                # JComputeStack
  # template   : ['id']                # JStackTemplate

  # Custom variables in Stack Templates
  #
  # Users can define and use following variables in their stack templates;
  #
  #   ${var.koding_SECTION_PROPERTY}
  #
  # where SECTION can be one of 'user', 'account' or 'group'
  # they are equavilent in Koding DB as JUser, JAccount and JGroup
  #
  # So when one uses ${var.koding_user_email} it will become current user's
  # JUser.email and so on. But the list of available properties defined
  # above, other properties won't be exposed.
  #
  # Also we are supporting userInputs which can be written as;
  #
  #   ${var.userInput_VARIABLENAME}
  #
  # If you write down ${var.userInput_studentNumber} which means we will
  # request to fill `studentNumber` information from end user.

  props        = []
  sections     = []

  # Build the regex based on the supported properties above
  for i, v of allowedProps
    sections   = sections.concat i
    props      = props.concat v

  props        = props.join    '|'
  sections     = sections.join '|'

  regexs       = [
    # This one extracts koding variables defined above
    # Check the example below for the regular expression definition
    # http://regexr.com/3bles ~ GG
    ///var\.koding\_(#{sections})\_(#{props})(\_([A-Za-z0-9\-_]+)|)///g

    # And this one for userInputs which will be asked to user when they
    # want to build their stacks which created from the stack template
    /var\.(userInput)\_([A-Za-z0-9\-_]+)/g

    # This is for custom data which will be asked from the admin
    # These variables needed to provide in custom variables section
    /var\.(custom)\_([A-Za-z0-9\-_]+)/g

    # This is for payload data which will be provided with the request
    # These variables will be posted dynamically, mostly over api calls
    /var\.(payload)\_([A-Za-z0-9\-_]+)/g
  ]

  requirements = {}

  # Execute each regular expression over the content
  for regex in regexs
    match = regex.exec content

    while match

      # Keeping matches as object keys to make them unique
      requirements[match[1]] ?= {}

      # If there are substrings like in following example;
      #   ${var.koding_account_profile_nickname}
      #
      # we need to convert this information to;
      #   JAccount.profile.nickname
      #
      # So the following check is providing that. This is only required
      # for subsequent properties like in JAccount, the rest provides
      # only one level deep properties so they are fine.
      substring = if match[4]
        "#{match[2]}.#{match[4..].join '.'}"
      else
        match[2]

      # Adding the substring as key so we can make it unique as well.
      requirements[match[1]][substring] = null
      match = regex.exec content

  # Cleanup the list and produce a simple list of requirements
  #
  #   { SECTION: [REQUESTED_PROPERTIES] }
  #
  # like
  #
  #   {
  #     'user': ['username', 'email']
  #     'account': ['profile.firstName']
  #     'group': ['title']
  #     'userInput': ['studentNumber']
  #   }
  for match of requirements
    requirements[match] = Object.keys requirements[match]

  return requirements
