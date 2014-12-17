package templates

const Content = `
    {{define "content"}}
    <tr class="content">
      <td class="time">
        <a href='#'>{{.ActivityTime}}</a>
      </td>
      <td class="inner" colspan="2">
          {{template "gravatar" . }}
          <div class="action">
            <a href="{{.Uri}}/{{.ActorContact.Username}}">
              {{.ActorContact.FirstName}} {{.ActorContact.LastName}}
            </a>
            {{.Action}}
            {{template "contentLink" . }}
            {{template "group" . }}
          </div>
          {{template "preview" . }}
      </td>
    </tr>
    {{end}}
`

const Gravatar = `
    {{define "gravatar"}}
    <img width="{{.Size}}px" height="{{.Size}}px" class="gravatar"
              src="https://gravatar.com/avatar/{{.ActorContact.Hash}}?size={{.Size}}&d=https%3A%2F%2Fkoding-cdn.s3.amazonaws.com%2Fimages%2Fdefault.avatar.{{.Size}}.png" />
    {{end}}
`

const ContentLink = `
    <a href="{{.Uri}}/Activity/Post/{{.Slug}}">
            {{.ObjectType}}
    </a>
`

const Group = `
    in <a href='{{.Uri}}/{{.Group.Slug}}'>
    {{.Group.Name}}</a> group.
`

const Preview = `
    <div class="preview">{{.Message}}</div>
`
