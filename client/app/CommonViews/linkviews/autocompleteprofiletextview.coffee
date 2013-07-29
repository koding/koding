class AutoCompleteProfileTextView extends ProfileTextView

  highlightMatch:(str, isNick=no)->

    {userInput} = @getOptions()
    unless userInput
      str
    else
      str = str.replace RegExp(userInput, 'gi'), (match)=>
        if isNick then @setClass 'nick-matches'
        return "<b>#{match}</b>"

  pistachio:->

    name = KD.utils.getFullnameFromAccount @getData()
    "{{@highlightMatch name}}" +
      if @getOptions().shouldShowNick then """
        <span class='nick'>
          (@{{@highlightMatch #(profile.nickname), yes}})
        </span>
        """
      else ''
