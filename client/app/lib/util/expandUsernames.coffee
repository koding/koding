$ = require 'jquery'
module.exports = (text, excludeSelector) ->
  # excludeSelector is a jQuery selector

  # as a JQuery selector, e.g. "pre"
  # means that all @s in <pre> tags will not be expanded

  return null unless text

  # default case for regular text
  if not excludeSelector
    text.replace /\B\@([\w\-]+)/gim, (u) ->
      username = u.replace "@", ""
      "<a href='/#{username}' class='profile-link'>#{u}</a>"

  # context-sensitive expansion
  else
    result = ""
    $(text).each (i, element) ->
      $element = $(element)
      elementCheck = $element.not excludeSelector
      parentCheck = $element.parents(excludeSelector).length is 0
      childrenCheck = $element.find(excludeSelector).length is 0
      if elementCheck and parentCheck and childrenCheck
        if $element.html()?
          replacedText =  $element.html().replace /\B\@([\w\-]+)/gim, (u) ->
            username = u.replace "@", ""
            u.link "/#{username}"
          $element.html replacedText
      result += $element.get(0).outerHTML or "" # in case there is a text-only element
    result
