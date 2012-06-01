JReply = jraphical.Reply

class JAnswer extends JReply
  @set
    schema        : JReply.schema
    relationships :
      comment     : JComment

# class CAnswerActivity extends CActivity
# 
#   @set
#     encapsulatedBy  : CActivity
#     relationships   :
#       message       : JAnswer
#       root          : JQuestion