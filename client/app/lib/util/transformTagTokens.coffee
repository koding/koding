module.exports = (text = '') ->

  tokenPattern = /\|#:JTag:.*?:(.*?)\|/g

  return text  unless tokenPattern.test text

  text.replace tokenPattern, (match, name) ->

    return "##{name.replace ' ', ''}"
