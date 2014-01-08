REPORTER = dot

# TODO check if mocha and docco are installed.
install:
	npm install

clean:
	cake clean	

dev:
	cake dev

build:
	cake build

test:
	cake test

tdd:
	mocha -c -w -b --compilers coffee:coffee-script

gen_test_keys:
	# openssl genrsa -des3 -passout pass:nosecret -out privkey.pem 2048
	openssl genrsa -out etc/rsa_key.pem 2048
	openssl rsa -in etc/rsa_key.pem -pubout > etc/rsa_pubkey.pem
	# Generate the RSA keys and certificate
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha1 -subj \
		'/C=US/ST=CA/L=San Francisco /CN=www.hashgo.com' -keyout \
		etc/mytest-rsakey.pem -out etc/mytest-rsacert.pem
	openssl pkcs12 -passout pass:notasecret -export -in etc/mytest-rsacert.pem -inkey etc/mytest-rsakey.pem -out etc/test-myrsacert.pi12 -name "Testing PKCS12 Certificate"

docs:
	cake docs

all: install build test

.PHONY: all 
