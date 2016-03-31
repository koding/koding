NO_COLOR=\033[0m
OK_COLOR=\033[0;32m

klient:
	@echo "$(OK_COLOR)==> Building klient $(NO_COLOR)"
	@`which go` build -v -ldflags "-X koding/klient/protocol.Version 0.0.1 -X koding/klient/protocol.Environment devbuild" ../klient
	@echo "$(OK_COLOR)==> Installing klient $(NO_COLOR)"
	@mv /opt/kite/klient/klient /opt/kite/klient/klient.old
	@sudo mv ./klient /opt/kite/klient/klient
	@sudo kd restart

klientctl:
	@echo "$(OK_COLOR)==> Building kd $(NO_COLOR)"
	@`which go` build -v ../klientctl
	@echo "$(OK_COLOR)==> Installing kd $(NO_COLOR)"
	@mv ./klientctl /usr/local/bin/kd

.PHONY: klient klientctl kd
