NO_COLOR=\033[0m
OK_COLOR=\033[0;32m

klient:
	@echo "$(OK_COLOR)==> Building klient $(NO_COLOR)"
	@`which go` build -v -ldflags "-X koding/klient/protocol.Version 0.0.1 -X koding/klient/protocol.Environment devbuild" -tags pprof ../klient
	@echo "$(OK_COLOR)==> Installing klient $(NO_COLOR)"
	@mv /opt/kite/klient/klient /opt/kite/klient/klient.old
	@sudo mv ./klient /opt/kite/klient/klient
	@sudo kd restart

klientctl:
	@echo "$(OK_COLOR)==> Building kd $(NO_COLOR)"
	@`which go` build -v -ldflags "-X koding/klientctl/config.Environment devbuild" ../klientctl
	@echo "$(OK_COLOR)==> Installing kd $(NO_COLOR)"
	@mv ./klientctl /usr/local/bin/kd

fusetest:
	@echo "$(OK_COLOR)==> Building fusetest $(NO_COLOR)"
	@`which go` build -v ../fusetest/cmd/fusetest
	@echo "$(OK_COLOR)==> Installing fusetest $(NO_COLOR)"
	@mv ./fusetest /usr/local/bin

.PHONY: klient klientctl kd
