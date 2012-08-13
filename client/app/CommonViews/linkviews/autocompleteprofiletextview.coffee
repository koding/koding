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

    "{{@highlightMatch #(profile.firstName)+' '+#(profile.lastName)}}" +
      if @getOptions().shouldShowNick then """
        <span class='nick'>
          (@{{@highlightMatch #(profile.nickname), yes}})
        </span>
        """
      else ''
