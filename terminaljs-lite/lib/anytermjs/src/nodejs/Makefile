BUILD_ROOT:=../../build/app/nodejs/lib
all: dirs terminal htmlify diff controller

terminal::
	cd terminal&&node-waf configure build install
	cp terminal/tests/*.js $(BUILD_ROOT)

htmlify::
	cd htmlify&&node-waf configure build install
	cp htmlify/tests/*.js $(BUILD_ROOT)

diff::
	cd diff&&node-waf configure build install
	cp diff/tests/*.js $(BUILD_ROOT)

controller::
	cd controller&&node-waf configure build install
	cp controller/tests/*.js $(BUILD_ROOT)

dirs::
	mkdir -p $(BUILD_ROOT)

clean::
	rm -fr $(BUILD_ROOT)/src
