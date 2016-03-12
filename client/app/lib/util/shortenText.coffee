module.exports = do ->
  tryToShorten = (longText, optimalBreak = ' ', suffix)->
    unless ~ longText.indexOf optimalBreak then no
    else
      "#{longText.split(optimalBreak).slice(0, -1).join optimalBreak}#{suffix ? optimalBreak}"

  (longText, options={})->
    return ''  unless longText
    minLength = options.minLength or 450
    maxLength = options.maxLength or 600
    suffix    = options.suffix     ? '...'


    tempText = longText.slice 0, maxLength
    lastClosingTag = tempText.lastIndexOf "]"
    lastOpeningTag = tempText.lastIndexOf "["

    if lastOpeningTag <= lastClosingTag
      finalMaxLength = maxLength
    else
      finalMaxLength = lastOpeningTag

    return longText if longText.length < minLength or longText.length < maxLength

    longText = longText.substr 0, finalMaxLength

    # prefer to end the teaser at the end of a sentence (a period).
    # failing that prefer to end the teaser at the end of a word (a space).
    candidate = tryToShorten(longText, '. ', suffix) or tryToShorten longText, ' ', suffix

    return \
      if candidate?.length > minLength then candidate
      else longText
