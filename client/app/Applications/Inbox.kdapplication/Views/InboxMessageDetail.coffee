class InboxMessageDetail extends KDView
  constructor:(options,data)->
    super

    origin = {
      constructorName  : data.originType
      id               : data.originId
    }

    group = data.participants.map (participant)->
      constructorName : participant.sourceName
      id              : participant.sourceId

    @author     = new ProfileLinkView {origin}
    @group      = new LinkGroup {group}
    @commentBox = new InboxMessageThreadView null, data
    @replyView  = new InboxReplyForm delegate : @commentBox.commentList

  pistachio:->
    """
    <div class='message-body'>
      <header>
        <h1>{{@utils.applyTextExpansions #(subject) or '(No Title)'}}</h1>
        <p>Conversation with <span class="profile-wrapper">{{> @group}}</span> <span class="add hidden">+</span></p>
      </header>
      <section>
        <div class='meta'>
          <span class="author-wrapper">{{> @author}}</span>
          <span class='time'>{{$.timeago #(meta.createdAt)}}</span>
        </div>
        <div>{{@enhanceBody #(body)}}</div>
      </section>
    </div>
    {{> @commentBox}}
    {{> @replyView}}
    """

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

    @fetchComments (err, comments)=>
      if comments.length
        @commentBox.commentController.replaceAllComments comments

  fetchComments:(callback)->
    pm = @getData()
    pm.commentsByRange to: 3, (err, comments)->
      callback err, comments

  enhanceBody:(body)->
    body or= "(No message body)"
    body = @utils.applyTextExpansions body
    body = body.replace /(\n|&#10;)/g, '<br>'
    return body
