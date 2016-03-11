package sneaker

import "github.com/aws/aws-sdk-go/service/kms"

type FakeKMS struct {
	GenerateInputs  []kms.GenerateDataKeyInput
	GenerateOutputs []kms.GenerateDataKeyOutput

	DecryptInputs  []kms.DecryptInput
	DecryptOutputs []kms.DecryptOutput
}

func (f *FakeKMS) GenerateDataKey(req *kms.GenerateDataKeyInput) (*kms.GenerateDataKeyOutput, error) {
	f.GenerateInputs = append(f.GenerateInputs, *req)
	resp := f.GenerateOutputs[0]
	f.GenerateOutputs = f.GenerateOutputs[1:]
	return &resp, nil
}

func (f *FakeKMS) Decrypt(req *kms.DecryptInput) (*kms.DecryptOutput, error) {
	f.DecryptInputs = append(f.DecryptInputs, *req)
	resp := f.DecryptOutputs[0]
	f.DecryptOutputs = f.DecryptOutputs[1:]
	return &resp, nil
}
