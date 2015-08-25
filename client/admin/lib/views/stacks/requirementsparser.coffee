module.exports = requirementsParser = (content) ->

    allowedProps =
      user       : ['username', 'email'] # JUser
      account    : ['profile']           # JAccount
      group      : ['title', 'slug']     # JGroup

    props        = []
    sections     = []

    for i, v of allowedProps
      sections   = sections.concat i
      props      = props.concat v

    props        = props.join '|'
    sections     = sections.join '|'

    # Check the example below
    # http://regexr.com/3blbp ~ GG

    regexs = [
      ///\$\{var\.koding\_(#{sections})\_(#{props})(\_(.*)\}|\})///g
      /\$\{var\.(userInput)\_(.*)\}/g
    ]

    requirements = {}

    for regex in regexs
      match = regex.exec content

      while match
        requirements[match[1]] ?= {}
        substring = if match[4]
          "#{match[2]}.#{match[4..].join '.'}"
        else
          match[2]
        requirements[match[1]][substring] = null
        match = regex.exec content

    for match of requirements
      requirements[match] = Object.keys requirements[match]

    return requirements