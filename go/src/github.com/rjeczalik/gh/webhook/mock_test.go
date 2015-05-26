// Created by go generate; DO NOT EDIT

package webhook

type DetailHandler map[string]int

func (dh DetailHandler) CommitComment(*CommitCommentEvent) {
	dh["commit_comment"]++
}

func (dh DetailHandler) Create(*CreateEvent) {
	dh["create"]++
}

func (dh DetailHandler) Delete(*DeleteEvent) {
	dh["delete"]++
}

func (dh DetailHandler) Deployment(*DeploymentEvent) {
	dh["deployment"]++
}

func (dh DetailHandler) DeploymentStatus(*DeploymentStatusEvent) {
	dh["deployment_status"]++
}

func (dh DetailHandler) Download(*DownloadEvent) {
	dh["download"]++
}

func (dh DetailHandler) Follow(*FollowEvent) {
	dh["follow"]++
}

func (dh DetailHandler) Fork(*ForkEvent) {
	dh["fork"]++
}

func (dh DetailHandler) ForkApply(*ForkApplyEvent) {
	dh["fork_apply"]++
}

func (dh DetailHandler) Gist(*GistEvent) {
	dh["gist"]++
}

func (dh DetailHandler) Gollum(*GollumEvent) {
	dh["gollum"]++
}

func (dh DetailHandler) IssueComment(*IssueCommentEvent) {
	dh["issue_comment"]++
}

func (dh DetailHandler) Issues(*IssuesEvent) {
	dh["issues"]++
}

func (dh DetailHandler) Member(*MemberEvent) {
	dh["member"]++
}

func (dh DetailHandler) Membership(*MembershipEvent) {
	dh["membership"]++
}

func (dh DetailHandler) PageBuild(*PageBuildEvent) {
	dh["page_build"]++
}

func (dh DetailHandler) Ping(*PingEvent) {
	dh["ping"]++
}

func (dh DetailHandler) Public(*PublicEvent) {
	dh["public"]++
}

func (dh DetailHandler) PullRequest(*PullRequestEvent) {
	dh["pull_request"]++
}

func (dh DetailHandler) PullRequestReviewComment(*PullRequestReviewCommentEvent) {
	dh["pull_request_review_comment"]++
}

func (dh DetailHandler) Push(*PushEvent) {
	dh["push"]++
}

func (dh DetailHandler) Release(*ReleaseEvent) {
	dh["release"]++
}

func (dh DetailHandler) Repository(*RepositoryEvent) {
	dh["repository"]++
}

func (dh DetailHandler) Status(*StatusEvent) {
	dh["status"]++
}

func (dh DetailHandler) TeamAdd(*TeamAddEvent) {
	dh["team_add"]++
}

func (dh DetailHandler) Watch(*WatchEvent) {
	dh["watch"]++
}

type BlanketHandler map[string]int

func (bh BlanketHandler) All(event string, _ interface{}) {
	bh[event]++
}
