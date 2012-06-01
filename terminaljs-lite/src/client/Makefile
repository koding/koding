BUILD_DIR:=$(shell pwd)../../build

all : build


build:anyterm.js

anyterm.js: $(BUILD_DIR)/anyterm
	@echo "anyterm.js installed "

$(BUILD_DIR)/anyterm ::
	$(MAKE) -C ../../lib/anytermjs install-scripts install-path=$@ clean-all
	npm --force install $@


.PHONY: anyterm.js
