package emailmodels

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRenderMessage(t *testing.T) {
	Convey("Message should be able to rendered", t, func() {
		mgs := NewMessageGroupSummary()
		m := &MessageSummary{}
		m.Body = "hehe"
		m.Time = "2:40 PM"
		mgs.Hash = "123123"
		mgs.Nickname = "canthefason"

		mgs.AddMessage(m)
		body := mgs.Render()
		So(body, ShouldContainSubstring, "canthefason")
		So(body, ShouldContainSubstring, "123123")
		So(body, ShouldContainSubstring, "2:40 PM")
		So(body, ShouldContainSubstring, "hehe")
	})
}
