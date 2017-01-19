module.exports = replaceUserInputs = (template) ->

  for [type, quote] in [['json', '\"'], ['yaml', '\'']]
    for key, val of template.defaults.userInputs
      val = "#{quote}#{val}#{quote}" if isNaN val
      template[type] = template[type]
        .replace ///#{quote}\$\{var.userInput_#{key}\}#{quote}///g, val

  template
