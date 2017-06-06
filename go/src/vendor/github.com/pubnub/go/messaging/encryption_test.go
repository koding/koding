// Package tests has the unit tests of package
// pubnubEncryption_test.go contains the tests related to the Encryption/Decryption of messages
package messaging

import (
	"bytes"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"log"
	"os"
	"testing"
	"unicode/utf16"
)

func TestPad(t *testing.T) {
	assert := assert.New(t)

	var badMsg interface{}
	b := []byte(`{
	"kind": "click",
	"user": {"key" : "user@test.com"},
	"creationDate": 9223372036854775808346,
	"key": "54651fa39868621628000002",
	"url": "http://www.google.com"
	}`)

	json.Unmarshal(b, &badMsg)
	jsonSerialized, _ := json.Marshal(badMsg)

	actual := EncryptString("enigma", fmt.Sprintf("%s", jsonSerialized))
	expected := "yzJ2MMyt8So18nNXm4m3Dqzb1G+as9LDqdlZ+p8iEGi358F5h25wmKrj9FTOPdMQ0TMy/Xhf3hS3+ZRUlv/zLD6/0Ns/c834HQMUmG+6DN9SQy9II3bkUGZu9Bn6Ng/ZmJTrHV7QnkLnjD+pGOHEvqrPEduR5pfA2n9mA3qQNhqFgnsIvffxGB0AqM57NdD3Tlr2ig8A2VI4Lh3DmX7f1Q=="

	assert.Equal(expected, actual)
}

func TestUnpad(t *testing.T) {
	assert := assert.New(t)

	message := "yzJ2MMyt8So18nNXm4m3Dl0XuYAOJFj2JXG8P3BGlCsDsqM44ReH15MRGbEkJZCSqgMiX1wUK44Qz8gsTcmGcZm/7KtOa+kRnvgDpNkTuBUrDqSjmYeuBLqRIEIfoGrRNljbFmP1W9Zv8iVbJMmovF+gmNNiIzlC3J9dHK51/OgW7s2EASMQJr3UJZ26PoFmmXY/wYN+2EyRnT4PBRCocQ=="
	decrypted, _ := DecryptString("enigma", message)

	decMessage := fmt.Sprintf("%s", decrypted)

	assert.Contains(decMessage, `"user":{"key":"user@test.com"}`)
	assert.Contains(decMessage, `"key":"54651fa39868621628000002"`)
}

// TestYayDecryptionBasic tests the yay decryption.
// Assumes that the input message is deserialized
// Decrypted string should match yay!
func TestYayDecryptionBasic(t *testing.T) {
	assert := assert.New(t)

	message := "q/xJqqN6qbiZMXYmiQC1Fw=="

	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)

	assert.Equal("yay!", decrypted)
}

// TestYayEncryptionBasic tests the yay encryption.
// Assumes that the input message is not serialized
// Decrypted string should match q/xJqqN6qbiZMXYmiQC1Fw==
func TestYayEncryptionBasic(t *testing.T) {
	assert := assert.New(t)

	message := "yay!"
	encrypted := EncryptString("enigma", message)

	assert.Equal("q/xJqqN6qbiZMXYmiQC1Fw==", encrypted)
}

// TestYayDecryption tests the yay decryption.
// Assumes that the input message is serialized
// Decrypted string should match yay!
func TestYayDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "Wi24KS4pcTzvyuGOHubiXg=="

	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)

	b, err := json.Marshal("yay!")
	assert.NoError(err)

	assert.Equal(string(b), decrypted)
}

// TestYayEncryption tests the yay encryption.
// Assumes that the input message is serialized
// Decrypted string should match q/xJqqN6qbiZMXYmiQC1Fw==
func TestYayEncryption(t *testing.T) {
	assert := assert.New(t)

	message := "yay!"
	b, err := json.Marshal(message)
	assert.NoError(err)

	encrypted := EncryptString("enigma", string(b))
	assert.Equal("Wi24KS4pcTzvyuGOHubiXg==", encrypted)
}

// TestArrayDecryption tests the slice decryption.
// Assumes that the input message is deserialized
// And the output message has to been deserialized.
// Decrypted string should match Ns4TB41JjT2NCXaGLWSPAQ==
func TestArrayDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "Ns4TB41JjT2NCXaGLWSPAQ=="
	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)
	slice := []string{}
	b, err := json.Marshal(slice)
	assert.NoError(err)

	assert.Equal(string(b), decrypted)
}

// TestArrayEncryption tests the slice encryption.
// Assumes that the input message is not serialized
// Decrypted string should match Ns4TB41JjT2NCXaGLWSPAQ==
func TestArrayEncryption(t *testing.T) {
	assert := assert.New(t)

	message := []string{}

	b, err := json.Marshal(message)
	assert.NoError(err)

	encrypted := EncryptString("enigma", string(b))
	assert.Equal("Ns4TB41JjT2NCXaGLWSPAQ==", encrypted)
}

// TestObjectDecryption tests the empty object decryption.
// Assumes that the input message is deserialized
// And the output message has to been deserialized.
// Decrypted string should match IDjZE9BHSjcX67RddfCYYg==
func TestObjectDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "IDjZE9BHSjcX67RddfCYYg=="
	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)

	emptyStruct := emptyStruct{}

	b, err := json.Marshal(emptyStruct)
	assert.NoError(err)
	assert.Equal(string(b), decrypted)
}

// TestObjectEncryption tests the empty object encryption.
// The output is not serialized
// Encrypted string should match the serialized object
func TestObjectEncryption(t *testing.T) {
	assert := assert.New(t)

	message := emptyStruct{}

	b, err := json.Marshal(message)
	assert.NoError(err)

	encrypted := EncryptString("enigma", string(b))

	assert.Equal("IDjZE9BHSjcX67RddfCYYg==", encrypted)
}

// TestMyObjectDecryption tests the custom object decryption.
// Assumes that the input message is deserialized
// And the output message has to been deserialized.
// Decrypted string should match BMhiHh363wsb7kNk7krTtDcey/O6ZcoKDTvVc4yDhZY=
func TestMyObjectDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "BMhiHh363wsb7kNk7krTtDcey/O6ZcoKDTvVc4yDhZY="
	decrypted, decErr := DecryptString("enigma", message)

	assert.NoError(decErr)
	customStruct := customStruct{
		Foo: "hi!",
		Bar: []int{1, 2, 3, 4, 5},
	}
	b, err := json.Marshal(customStruct)
	assert.NoError(err)
	assert.Equal(string(b), decrypted)
}

// TestMyObjectEncryption tests the custom object encryption.
// The output is not serialized
// Encrypted string should match the serialized object
func TestMyObjectEncryption(t *testing.T) {
	assert := assert.New(t)

	message := customStruct{
		Foo: "hi!",
		Bar: []int{1, 2, 3, 4, 5},
	}

	b1, err := json.Marshal(message)
	assert.NoError(err)

	encrypted := EncryptString("enigma", string(b1))
	assert.Equal("BMhiHh363wsb7kNk7krTtDcey/O6ZcoKDTvVc4yDhZY=", encrypted)
}

// TestPubNubDecryption2 tests the Pubnub Messaging API 2 decryption.
// Assumes that the input message is deserialized
// Decrypted string should match Pubnub Messaging API 2
func TestPubNubDecryption2(t *testing.T) {
	assert := assert.New(t)

	message := "f42pIQcWZ9zbTbH8cyLwB/tdvRxjFLOYcBNMVKeHS54="
	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)

	b, err := json.Marshal("Pubnub Messaging API 2")
	assert.NoError(err)
	assert.Equal(string(b), decrypted)
}

// TestPubNubEncryption2 tests the Pubnub Messaging API 2 encryption.
// Assumes that the input message is not serialized
// Decrypted string should match f42pIQcWZ9zbTbH8cyLwB/tdvRxjFLOYcBNMVKeHS54=
func TestPubNubEncryption2(t *testing.T) {
	assert := assert.New(t)

	message := "Pubnub Messaging API 2"
	b, err := json.Marshal(message)
	assert.NoError(err)

	encrypted := EncryptString("enigma", string(b))
	assert.Equal("f42pIQcWZ9zbTbH8cyLwB/tdvRxjFLOYcBNMVKeHS54=", encrypted)
}

// TestPubNubDecryption tests the Pubnub Messaging API 1 decryption.
// Assumes that the input message is deserialized
// Decrypted string should match Pubnub Messaging API 1
func TestPubNubDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "f42pIQcWZ9zbTbH8cyLwByD/GsviOE0vcREIEVPARR0="
	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)

	b, err := json.Marshal("Pubnub Messaging API 1")
	assert.NoError(err)
	assert.Equal(string(b), decrypted)
}

// TestPubNubEncryption tests the Pubnub Messaging API 1 encryption.
// Assumes that the input message is not serialized
// Decrypted string should match f42pIQcWZ9zbTbH8cyLwByD/GsviOE0vcREIEVPARR0=
func TestPubNubEncryption(t *testing.T) {
	assert := assert.New(t)

	message := "Pubnub Messaging API 1"
	b, err := json.Marshal(message)
	assert.NoError(err)
	encrypted := EncryptString("enigma", string(b))
	assert.Equal("f42pIQcWZ9zbTbH8cyLwByD/GsviOE0vcREIEVPARR0=", encrypted)
}

// TestStuffCanDecryption tests the StuffCan decryption.
// Assumes that the input message is deserialized
// Decrypted string should match {\"this stuff\":{\"can get\":\"complicated!\"}}
func TestStuffCanDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "zMqH/RTPlC8yrAZ2UhpEgLKUVzkMI2cikiaVg30AyUu7B6J0FLqCazRzDOmrsFsF"
	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)
	assert.Equal("{\"this stuff\":{\"can get\":\"complicated!\"}}", decrypted)
}

// TestStuffCanEncryption tests the StuffCan encryption.
// Assumes that the input message is not serialized
// Decrypted string should match zMqH/RTPlC8yrAZ2UhpEgLKUVzkMI2cikiaVg30AyUu7B6J0FLqCazRzDOmrsFsF
func TestStuffCanEncryption(t *testing.T) {
	assert := assert.New(t)

	message := "{\"this stuff\":{\"can get\":\"complicated!\"}}"
	encrypted := EncryptString("enigma", message)
	assert.Equal("zMqH/RTPlC8yrAZ2UhpEgLKUVzkMI2cikiaVg30AyUu7B6J0FLqCazRzDOmrsFsF", encrypted)
}

// TestHashDecryption tests the hash decryption.
// Assumes that the input message is deserialized
// Decrypted string should match {\"foo\":{\"bar\":\"foobar\"}}
func TestHashDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "GsvkCYZoYylL5a7/DKhysDjNbwn+BtBtHj2CvzC4Y4g="
	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)
	assert.Equal("{\"foo\":{\"bar\":\"foobar\"}}", decrypted)
}

// TestHashEncryption tests the hash encryption.
// Assumes that the input message is not serialized
// Decrypted string should match GsvkCYZoYylL5a7/DKhysDjNbwn+BtBtHj2CvzC4Y4g=
func TestHashEncryption(t *testing.T) {
	assert := assert.New(t)

	message := "{\"foo\":{\"bar\":\"foobar\"}}"

	encrypted := EncryptString("enigma", message)
	assert.Equal("GsvkCYZoYylL5a7/DKhysDjNbwn+BtBtHj2CvzC4Y4g=", encrypted)
}

// TestUnicodeDecryption tests the Unicode decryption.
// Assumes that the input message is deserialized
// Decrypted string should match 漢語
func TestUnicodeDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "+BY5/miAA8aeuhVl4d13Kg=="
	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)

	pubInstance := Pubnub{
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	data, _, _, err := pubInstance.ParseJSON([]byte(decrypted.(string)), "")
	assert.NoError(err)
	assert.Equal("漢語", data)
}

// UTF16ToString returns the UTF-8 encoding of the UTF-16 sequence s,
// with a terminating NUL removed.
func UTF16ToString(s []uint16) []rune {
	for i, v := range s {
		if v == 0 {
			s = s[0:i]
			break
		}
	}
	return utf16.Decode(s)
}

// TestUnicodeEncryption tests the Unicode encryption.
// Assumes that the input message is not serialized
// Decrypted string should match +BY5/miAA8aeuhVl4d13Kg==
func TestUnicodeEncryption(t *testing.T) {
	assert := assert.New(t)

	message := "漢語"
	b, err := json.Marshal(message)
	assert.NoError(err)

	encrypted := EncryptString("enigma", string(b))
	assert.Equal("+BY5/miAA8aeuhVl4d13Kg==", encrypted)
}

// TestGermanDecryption tests the German decryption.
// Assumes that the input message is deserialized
// Decrypted string should match ÜÖ
func TestGermanDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "stpgsG1DZZxb44J7mFNSzg=="
	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)

	pubInstance := Pubnub{
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	data, _, _, err := pubInstance.ParseJSON([]byte(decrypted.(string)), "")
	assert.NoError(err)
	assert.Equal("ÜÖ", data)
}

// TestGermanEncryption tests the German encryption.
// Assumes that the input message is not serialized
// Decrypted string should match stpgsG1DZZxb44J7mFNSzg==
func TestGermanEncryption(t *testing.T) {
	assert := assert.New(t)

	message := "ÜÖ"
	b, err := json.Marshal(message)
	assert.NoError(err)

	encrypted := EncryptString("enigma", string(b))
	assert.Equal("stpgsG1DZZxb44J7mFNSzg==", encrypted)
}

// TestComplexClassDecryption tests the complex struct decryption.
// Decrypted string should match Bc846Ri5HK1ixqP/dzAyZq23Z/NBlcPn2UX8h38xTGINs72yF5gtU0t9fFEMxjY+DmezWt0nG7eN7RABrj697tK1nooVHYIxgDLMsjMTw5N0K+rUM823n7LcHfEoXaX8oH2E6zkg6iK5pmT8nlh6LF6Bw1G5zkluT8oTjnbFJcpEvTyT2ZKzcqptgYsE9XZiqgBMEfYqwphDzmOv+TjHkJai+paV0rzFxIfVK8KHCA14z+1kKDMPghlmzx2tUmmbQb04hjhvgDvvi3tknytYVqJo1L5jZkAZTVXRfed7wq+L+1V824c9AwVsG9iCv15/Jemjjfzk07MXawk+hjmQvjQDWLS/ww3vwkNXiuJITbVCPOBADwJhBnFqkkb/Hd8LaKwyFhWeXwoZWbqugDoYufUzJApf4Nl/4RthYoisqJIokmxiWvYeD1TuH+C457kDaEu3aJd+KdLf8k9QkmaDNqkZo9Z/BRkZ63oMna1aEBy7bSE3l/lw40dnhsMaYfYk
func TestComplexClassDecryption(t *testing.T) {
	assert := assert.New(t)

	message := "Bc846Ri5HK1ixqP/dzAyZq23Z/NBlcPn2UX8h38xTGINs72yF5gtU0t9fFEMxjY+DmezWt0nG7eN7RABrj697tK1nooVHYIxgDLMsjMTw5N0K+rUM823n7LcHfEoXaX8oH2E6zkg6iK5pmT8nlh6LF6Bw1G5zkluT8oTjnbFJcpEvTyT2ZKzcqptgYsE9XZiEn84zv0wjDMxSJzlM7cbe2JpLtR99mdkUf8SMVr+J0ym6Z9c02MKLP6bygWzdG9zTdkLSIxJE3R9Yt76XeRFdrbRNWkuQM/uItDsE23+8RKwZRyAScoDMwFAg+BSa6KF1tS6cJlyjxA8o5e9iWykKuHO0h1uAiapzTx9iZluOH2bVZgTUu1GABjXveMBAkrZ1eG4nVOlytsAr1oSekKvWxzyUEP2kFSrtQbg6oGECb1OMmj5bd21cx0vpDWr/juGT7/n4sBr7gYsWDvBaU7awN9Y7bcq14jtiXq/2iNNW0zoI3xe6+qByimHaiAgVoqO"

	decrypted, decErr := DecryptString("enigma", message)
	assert.NoError(decErr)

	customComplexMessage := initComplexMessage()
	b, err := json.Marshal(customComplexMessage)

	assert.NoError(err)
	assert.Equal(string(b), decrypted)
}

// TestComplexClassEncryption tests the complex struct encryption.
// Encrypted string should match Bc846Ri5HK1ixqP/dzAyZq23Z/NBlcPn2UX8h38xTGINs72yF5gtU0t9fFEMxjY+DmezWt0nG7eN7RABrj697tK1nooVHYIxgDLMsjMTw5N0K+rUM823n7LcHfEoXaX8oH2E6zkg6iK5pmT8nlh6LF6Bw1G5zkluT8oTjnbFJcpEvTyT2ZKzcqptgYsE9XZiqgBMEfYqwphDzmOv+TjHkJai+paV0rzFxIfVK8KHCA14z+1kKDMPghlmzx2tUmmbQb04hjhvgDvvi3tknytYVqJo1L5jZkAZTVXRfed7wq+L+1V824c9AwVsG9iCv15/Jemjjfzk07MXawk+hjmQvjQDWLS/ww3vwkNXiuJITbVCPOBADwJhBnFqkkb/Hd8LaKwyFhWeXwoZWbqugDoYufUzJApf4Nl/4RthYoisqJIokmxiWvYeD1TuH+C457kDaEu3aJd+KdLf8k9QkmaDNqkZo9Z/BRkZ63oMna1aEBy7bSE3l/lw40dnhsMaYfYk
func TestComplexClassEncryption(t *testing.T) {
	assert := assert.New(t)

	customComplexMessage := initComplexMessage()

	b1, err := json.Marshal(customComplexMessage)
	assert.NoError(err)

	encrypted := EncryptString("enigma", string(b1))
	assert.Equal("Bc846Ri5HK1ixqP/dzAyZq23Z/NBlcPn2UX8h38xTGINs72yF5gtU0t9fFEMxjY+DmezWt0nG7eN7RABrj697tK1nooVHYIxgDLMsjMTw5N0K+rUM823n7LcHfEoXaX8oH2E6zkg6iK5pmT8nlh6LF6Bw1G5zkluT8oTjnbFJcpEvTyT2ZKzcqptgYsE9XZiEn84zv0wjDMxSJzlM7cbe2JpLtR99mdkUf8SMVr+J0ym6Z9c02MKLP6bygWzdG9zTdkLSIxJE3R9Yt76XeRFdrbRNWkuQM/uItDsE23+8RKwZRyAScoDMwFAg+BSa6KF1tS6cJlyjxA8o5e9iWykKuHO0h1uAiapzTx9iZluOH2bVZgTUu1GABjXveMBAkrZ1eG4nVOlytsAr1oSekKvWxzyUEP2kFSrtQbg6oGECb1OMmj5bd21cx0vpDWr/juGT7/n4sBr7gYsWDvBaU7awN9Y7bcq14jtiXq/2iNNW0zoI3xe6+qByimHaiAgVoqO", encrypted)
}

// Data represents a <data> element.
type data struct {
	XMLName xml.Name `xml:"data"`
	//Entry   []Entry  `xml:"entry"`
	Name string `xml:"name"`
	Age  int    `xml:"age"`
}

// PubnubDemoMessage is a struct to test a non-alphanumeric message
type pubnubDemoMessage struct {
	DefaultMessage string `json:",string"`
}

// CustomComplexMessage is used to test the custom structure encryption and decryption.
// The variables "foo" and "bar" as used in the other languages are not
// accepted by golang and give an empty value when serialized, used "Foo"
// and "Bar" instead.
type customComplexMessage struct {
	VersionID     float32 `json:",string"`
	TimeToken     int64   `json:",string"`
	OperationName string
	Channels      []string
	DemoMessage   pubnubDemoMessage `json:",string"`
	SampleXML     string            `json:",string"`
}

// InitComplexMessage initializes a complex structure of the
// type CustomComplexMessage which includes a xml, struct of type PubnubDemoMessage,
// strings, float and integer.
func initComplexMessage() customComplexMessage {
	pubnubDemoMessage := pubnubDemoMessage{
		DefaultMessage: "~!@#$%^&*()_+ `1234567890-= qwertyuiop[]\\ {}| asdfghjkl;' :\" zxcvbnm,./ <>? ",
	}

	xmlDoc := &data{Name: "Doe", Age: 42}

	output := new(bytes.Buffer)
	enc := xml.NewEncoder(output)

	err := enc.Encode(xmlDoc)
	if err != nil {
		fmt.Printf("error: %v\n", err)
		return customComplexMessage{}
	}

	customComplexMessage := customComplexMessage{
		VersionID:     3.4,
		TimeToken:     13601488652764619,
		OperationName: "Publish",
		Channels:      []string{"ch1", "ch 2"},
		DemoMessage:   pubnubDemoMessage,
		SampleXML:     output.String(),
	}
	return customComplexMessage
}

// EmptyStruct provided the empty struct to test the encryption.
type emptyStruct struct {
}

// CustomStruct to test the custom structure encryption and decryption
// The variables "foo" and "bar" as used in the other languages are not
// accepted by golang and give an empty value when serialized, used "Foo"
// and "Bar" instead.
type customStruct struct {
	Foo string
	Bar []int
}

func CreateLoggerForTests() *log.Logger {
	var infoLogger *log.Logger
	logfileName := "pubnubMessagingTests.log"
	f, err := os.OpenFile(logfileName, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {
		fmt.Println("error opening file: ", err.Error())
		fmt.Println("Logging disabled")
	} else {
		//fmt.Println("Logging enabled writing to ", logfileName)
		infoLogger = log.New(f, "", log.Ldate|log.Ltime|log.Lshortfile)
	}
	return infoLogger
}
