class AppInfoView extends KDScrollView
  constructor:->
    super
    app = @getData()
    script = app.attachments[0]
    reqs = app.attachments[1]
    scriptData = {syntax : script.syntax, content : Encoder.htmlEncode(script.content), title : ""}
    requirementsData = {syntax : reqs.syntax, content : Encoder.htmlEncode(reqs.content), title : ""}
    @installScript = new AppCodeSnippetView {}, scriptData
    @requirementsScript = new AppCodeSnippetView {}, requirementsData

  viewAppended:->
    app = @getData()
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <header><a href='#'>About {{#(title)}}</a></header>
    <section>{{#(body)}}</section>
    <header><a href='#'>Technical Stuff</a></header>
    <section>
      <p>{{#(attachments.0.description)}}<p>
      {{> @installScript}}
      {{> @requirementsScript}}
    </section>
    """
