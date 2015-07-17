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
	Impersonating bool
	Version       string
	Title         string
	Description   string
	ShareUrl      string
	GpImage       string
	FbImage       string
	TwImage       string
	Segment       string
	Runtime       config.RuntimeOptions
	User          *LoggedInUser
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
	hc.User = u
	hc.Impersonating = impBool

	var buf bytes.Buffer
	if err := homeTmpl.Execute(&buf, hc); err != nil {
		Log.Error("Failed to render loggedin page: %s", err)
		writeLoggedOutHomeToResp(w)

		return
	}

	fmt.Fprint(w, buf.String())
}

func writeLoggedOutHomeToResp(w http.ResponseWriter) {
	homeTmpl := buildHomeTemplate(templates.LoggedOutHome)

	hc := buildHomeContent()

	var buf bytes.Buffer
	if err := homeTmpl.Execute(&buf, hc); err != nil {
		Log.Error("Failed to render loggedout page: %s", err)
	}

	fmt.Fprint(w, buf.String())
}

func buildHomeContent() HomeContent {
	hc := HomeContent{
		Version:     conf.Version,
		ShareUrl:    conf.Client.RuntimeOptions.MainUri,
		Segment:     conf.Segment,
		Title:       kodingTitle,
		Description: kodingDescription,
		GpImage:     kodingGpImage,
		FbImage:     kodingFbImage,
		TwImage:     kodingTwImage,
		Runtime:     conf.Client.RuntimeOptions,
	}

	return hc
}

func buildHomeTemplate(content string) *template.Template {
	homeTmpl := template.Must(template.New("home").Parse(content))
	headerTmpl := template.Must(template.New("header").Parse(templates.Header))

	homeTmpl.AddParseTree("header", headerTmpl.Tree)

	return homeTmpl
}
