NO_COLOR=\033[0m
OK_COLOR=\033[0;32m

klient:
	@echo "$(OK_COLOR)==> Building klient $(NO_COLOR)"
	@cd klient
  @go build -v -ldflags "-X koding/klient/protocol.Version 0.1.200 -X koding/klient/protocol.Environment managed"
	@echo "$(OK_COLOR)==> Installing klient $(NO_COLOR)"
  @sudo cp klient /opt/kite/klient/klient.new
  @sudo kd stop
  @sudo mv /opt/kite/klient/klient /opt/kite/klient/klient.old
  @sudo mv /opt/kite/klient/klient.new /opt/kite/klient/klient
  @sudo kd start

kd:
	@echo "$(OK_COLOR)==> Building kd $(NO_COLOR)"
	@cd klientctl
  @go build
	@echo "$(OK_COLOR)==> Installing kd $(NO_COLOR)"
  @sudo cp klientctl /usr/local/bin/kd
