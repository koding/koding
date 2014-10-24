package main

import (
	"bytes"
	"fmt"
	"html/template"
	"koding/go-webserver/templates"
	"koding/tools/config"
	"net/http"
)

type HomeContent struct {
	Version       string
	Runtime       config.RuntimeOptions
	User          map[string]interface{}
	Title         string
	Description   string
	ShareUrl      string
	Impersonating bool
}

func writeLoggedInHomeToResp(w http.ResponseWriter, u *LoggedInUser) {
	homeTmpl := buildHomeTemplate(templates.LoggedInHome)

	imp, ok := u.Get("Impersonating")
	if !ok {
		imp = false
	}

	impBool, ok := imp.(bool)
	if !ok {
		impBool = false
	}

	hc := buildHomeContent()
	hc.Runtime = conf.Client.RuntimeOptions
	hc.User = u.Data
	hc.Impersonating = impBool

	var buf bytes.Buffer
	if err := homeTmpl.Execute(&buf, hc); err != nil {
		Log.Error("Failed to render loggedin page: %s", err)
		writeLoggedOutHomeToResp(w)

		return
	}

	fmt.Fprintf(w, buf.String())
}

func writeLoggedOutHomeToResp(w http.ResponseWriter) {
	homeTmpl := buildHomeTemplate(templates.LoggedOutHome)

	hc := buildHomeContent()

	var buf bytes.Buffer
	if err := homeTmpl.Execute(&buf, hc); err != nil {
		Log.Error("Failed to render loggedout page: %s", err)
	}

	fmt.Fprintf(w, buf.String())
}

func buildHomeContent() HomeContent {
	hc := HomeContent{
		Version:     conf.Version,
		ShareUrl:    conf.Client.RuntimeOptions.MainUri,
		Title:       kodingTitle,
		Description: kodingDescription,
	}

	return hc
}

func buildHomeTemplate(content string) *template.Template {
	homeTmpl := template.Must(template.New("home").Parse(content))
	headerTmpl := template.Must(template.New("header").Parse(templates.Header))
	analyticsTmpl := template.Must(template.New("analytics").Parse(templates.Analytics))

	homeTmpl.AddParseTree("header", headerTmpl.Tree)
	homeTmpl.AddParseTree("analytics", analyticsTmpl.Tree)

	return homeTmpl
}
