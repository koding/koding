package models

import (
	. "github.com/smartystreets/goconvey/convey"
	"socialapi/config"
	"testing"
)

func TestTemplateRender(t *testing.T) {
	uc := UserContact{}

	Convey("Daily email", t, func() {
		Convey("Should load a correct config", func() {
			So(func() { config.MustRead("./test.toml") }, ShouldNotPanic)

			Convey("Should load a template parser", func() {
				tp := NewTemplateParser()
				tp.UserContact = &uc

				So(tp, ShouldNotBeNil)

				err := tp.validateTemplateParser()
				So(err, ShouldBeNil)

				Convey("Should be able to inline css from style.css", func() {
					base := "<html><head></head><body><a href='test'>test</a></body></html>"
					html := tp.inlineCss(base)

					So(html, ShouldNotBeNil)
					So(html, ShouldNotEqual, base)
					So(html, ShouldContainSubstring, "style=")
				})

				Convey("Should be able to inline css from style.css", func() {
					var containers []*MailerContainer
					html, err := tp.RenderDailyTemplate(containers)

					So(err, ShouldBeNil)
					So(html, ShouldNotBeNil)
					So(html, ShouldContainSubstring, "style=")
				})
			})
		})
	})
}
