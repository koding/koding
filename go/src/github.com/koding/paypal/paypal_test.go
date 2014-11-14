package paypal_test

import (
  "../paypal"
	"testing"
	"os"
  "strings"
)

const (
  TEST_RETURN_URL = "http://localhost/RETURN-URL"
  TEST_CANCEL_URL = "http://localhost/CANCEL-URL"
)

func fetchEnvVars(t *testing.T) (username, password, signature string) {
  username = os.Getenv("PAYPAL_TEST_USERNAME")
	if len(username) <= 0 {
		t.Fatalf("Test cannot run because cannot get environment variable PAYPAL_TEST_USERNAME")
	}
  password = os.Getenv("PAYPAL_TEST_PASSWORD")
	if len(password) <= 0 {
		t.Fatalf("Test cannot run because cannot get environment variable PAYPAL_TEST_PASSWORD")
	}
  signature = os.Getenv("PAYPAL_TEST_SIGNATURE")
	if len(signature) <= 0 {
		t.Fatalf("Test cannot run because cannot get environment variable PAYPAL_TEST_SIGNATURE")
	}
  return
}

func TestSandboxRedirect(t *testing.T) {
  username, password, signature := fetchEnvVars(t)
  
  client := paypal.NewDefaultClient(username, password, signature, true)  
	
	// Make a array of your digital-goods
	testGoods := []paypal.PayPalDigitalGood{paypal.PayPalDigitalGood{
    Name: "Test Good", 
    Amount: 200.000,
    Quantity: 5,
  }}
  
  // Sum amounts and get the token!
	response, err := client.SetExpressCheckoutDigitalGoods(paypal.SumPayPalDigitalGoodAmounts(&testGoods), 
    "USD", 
    TEST_RETURN_URL, 
    TEST_CANCEL_URL, 
    testGoods,
  )
  
  if err != nil {
    t.Errorf("Error returned in SetExpressCheckoutDigitalGoods: %#v.", err)
  }
	
  if len(response.Values["TOKEN"][0]) <= 0 {
    t.Errorf("Didn't get token back from PayPal. Response was: %#v", response.Values)
  }
	
  if response.Values["ACK"][0] != "Success" {
    t.Errorf("Didn't get ACK=Success back from PayPal. Response was: %#v", response.Values)
  }
  
  if strings.Index(response.CheckoutUrl(), response.Values["TOKEN"][0]) < 0 {
    t.Errorf("Couldnt find TOKEN in response.CheckoutUrl(). response.CheckoutUrl() was: %s when token was: %s", response.CheckoutUrl(),response.Values["TOKEN"][0]) 
  }
}

func TestErroneousDoExpressCheckoutSale(t *testing.T) {
  username, password, signature := fetchEnvVars(t)
  
  client := paypal.NewDefaultClient(username, password, signature, true)  
  response, err := client.DoExpressCheckoutSale("Fake_Token", "Fake_PayerId", "USD", 1000.00)
    
  if err != nil {
    // as expected 
  } else { // successful transaction would be wrong
    t.Errorf("Expected an error during transaction, but got a successful transaction: %#v.", response)
  }
}


func TestErroneousGetExpressCheckoutDetails(t *testing.T) {
  username, password, signature := fetchEnvVars(t)
  
  client := paypal.NewDefaultClient(username, password, signature, true)  
  response, err := client.GetExpressCheckoutDetails("Fake_Token")
  if err != nil {
    // as expected 
  } else { // successful transaction would be wrong
    t.Errorf("Expected an error during transaction, but got a successful transaction: %#v.", response)
  }
}