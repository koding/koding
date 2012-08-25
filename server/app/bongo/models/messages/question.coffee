JMessage = jraphical.Message

class JQuestion extends JMessage
  {secure} = require 'bongo'
  
  @share()

  @set
    sharedMethods   :
      instance      : ['addAnswer','addComment','voteUp','voteDown','fetchEntireMessage']
      static        : ['create','entireMessage','one']
    schema          : JMessage.schema
    relationships   :
      comment       : JComment
      answer        : JAnswer

  @entireMessage = secure (client, selector, callback)->
    @one {selector}, (err, message)->
      if err
        callback err
      else
        callback undefined unless message?.fetchEntireMessage callback

  # @test = secure (client, callback)->
  #   @create client,
  #     subject : 'Milo rulez!'
  #     body    : "He's the King of the Land!"
  #   , (err, message)->
  #     comment =  new JComment
  #       subject : 'Yeah!'
  #       body    : 'I agree!  Milo Rulez111!!!'
  #     comment.sign client.connection.delegate
  #     comment.save (err)->
  #       message.addComment comment, (err)->
  #         if err
  #           callback err
  #         else
  #           message.fetchEntireMessage callback

  @create = secure ({connection}, data, callback)->
    account = connection.delegate
    unless account instanceof JAccount
      callback new Error 'Please sign in to participate in the discussion.'
    else
      @uber 'create', connection.delegate, data, (err, message)->
        if err
          callback err
        else
          account.addQuestion message, (err)->
            callback? err, message

  voteUp: secure ({connection}, callback)->
  voteDown: secure ({connection}, callback)->

  fetchEntireMessage: secure (client, callback)->
    @beginGraphlet()
      .edges(targetName: $in: ['JComment','JAnswer'])
      .nodes()
      .edges(targetName: 'JComment')
      .nodes()
    .endGraphlet()
    .then (err, pipeline)->
      if err
        callback err
      else
        {graphlet} = pipeline.last()
        callback null, graphlet[0] # multiple root elements may need to go?

class CQuestionActivity extends CActivity

  @set
    encapsulatedBy  : CActivity
    relationships   :
      message       : JQuestion