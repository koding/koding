package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/config"
	"socialapi/workers/common/response"
	"socialapi/workers/gatekeeper/models"
	"strings"
)

var (
	ErrInvalidRequest = errors.New("invalid request")
	pub               *models.Pubnub
)

type Handler struct {
	Realtime models.Realtime
}

func NewHandler(r models.Realtime) *Handler {
	return &Handler{
		Realtime: r,
	}
}

func (h *Handler) Authenticate(u *url.URL, header http.Header, req *models.ChannelRequest) (int, http.Header, interface{}, error) {
	cookie := header.Get("Cookie")

	if err := checkParticipation(u, cookie, req); err != nil {
		return response.NewAccessDenied(err)
	}

	// user has access permission, now authenticate user to channel via pubnub
	if err := h.Realtime.Authenticate(req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

func (h *Handler) Push(u *url.URL, _ http.Header, req *models.MessageRequest) (int, http.Header, interface{}, error) {
	if ok := isRequestValid(req.Request); !ok {
		return response.NewBadRequest(ErrInvalidRequest)
	}

	if err := h.Realtime.Push(req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

func isRequestValid(req models.Request) bool {
	return req.Name != "" && req.Group != "" && req.Type != ""
}

func checkParticipation(u *url.URL, cookie string, req *models.ChannelRequest) error {

	if ok := isRequestValid(req.Request); !ok {
		return ErrInvalidRequest
	}

	cookies := parseCookies(cookie)
	endpoint := "/channel/checkparticipation"
	fullPath := prepareQueryString(endpoint, map[string]string{
		"name":  req.Name,
		"group": req.Group,
		"type":  req.Type,
	})

	client := new(http.Client)
	request, err := http.NewRequest("GET", fullPath, nil)
	for _, cookie := range cookies {
		request.AddCookie(cookie)
	}

	resp, err := client.Do(request)
	if err != nil {
		return err
	}

	if resp.StatusCode != 200 {
		return fmt.Errorf(resp.Status)
	}

	return nil
}

func authenticate(req *models.ChannelRequest) error {

	return fmt.Errorf("not implemented")
}

func prepareQueryString(endpoint string, params map[string]string) string {
	conf := config.MustGet()
	if len(params) == 0 {
		return endpoint
	}

	// TODO make it configurable
	fullPath := fmt.Sprintf("%s//localhost:7000%s?", conf.Protocol, endpoint)
	for key, value := range params {
		fullPath = fmt.Sprintf("%s%s=%s&", fullPath, key, value)
	}

	return fullPath[0 : len(fullPath)-1]
}

func parseCookies(cookie string) []*http.Cookie {
	pairs := strings.Split(cookie, "; ")
	cookies := make([]*http.Cookie, 0)

	if len(pairs) == 0 {
		return cookies
	}

	for _, val := range pairs {
		cp := strings.Split(val, "=")
		if len(cp) != 2 {
			continue
		}

		c := new(http.Cookie)
		c.Name = cp[0]
		c.Value = cp[1]

		cookies = append(cookies, c)
	}

	return cookies
}
