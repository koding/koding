module.exports = (email) ->
  emailPattern = /// ^ #begin of line
   ([\w.-]+)         #one or more letters, numbers, _ . or -
   @                 #followed by an @ sign
   ([\w.-]+)         #then one or more letters, numbers, _ . or -
   \.                #followed by a period
   ([a-zA-Z.]{2,6})  #followed by 2 to 6 letters or periods
   $ ///i            #end of line and ignore case

  return emailPattern.test email