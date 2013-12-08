class ActivityCommentView extends JView

  constructor:(options = {}, data)->

    options.charLimit or= 15
    super options, data

    {body} = @getData()
    @trimmedBody = @trimComment body, options.charLimit

  pistachio: ->
    "#{@trimmedBody}"

  trimComment: (comment, charLimit) ->
    tokenizedComment = @expandTokens comment
    if tokenizedComment.length > charLimit then "\"#{tokenizedComment.substring(0, charLimit)}...\""
    else "\"#{tokenizedComment}\""

  #CtF -Beware: highly copy/pasted code area. Find another way.
  expandTokens: (str = "") ->
    return  str unless tokenMatches = str.match /\|.+?\|/g

    data = @getData()
    tagMap = @getTokenMap data.tags  if data.tags

    for tokenString in tokenMatches
      [prefix, constructorName, id] = @decodeToken tokenString

      switch prefix
        when "#" then token = tagMap?[id]
        else continue

      continue  unless token

      str = str.replace tokenString, "##{token.title}"

    return  str

  decodeToken: (str) ->
    return  match[1].split /:/g  if match = str.match /^\|(.+)\|$/

  getTokenMap: (tokens) ->
    return  unless tokens
    map = {}
    tokens.forEach (token) -> map[token.getId()] = token
    return  map