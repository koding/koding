package sneaker

import "github.com/aws/aws-sdk-go/service/s3"

type FakeS3 struct {
	ListInputs  []s3.ListObjectsInput
	ListOutputs []s3.ListObjectsOutput

	DeleteInputs  []s3.DeleteObjectInput
	DeleteOutputs []s3.DeleteObjectOutput

	PutInputs  []s3.PutObjectInput
	PutOutputs []s3.PutObjectOutput

	GetInputs  []s3.GetObjectInput
	GetOutputs []s3.GetObjectOutput
}

func (f *FakeS3) ListObjects(req *s3.ListObjectsInput) (*s3.ListObjectsOutput, error) {
	f.ListInputs = append(f.ListInputs, *req)
	resp := f.ListOutputs[0]
	f.ListOutputs = f.ListOutputs[1:]
	return &resp, nil
}

func (f *FakeS3) DeleteObject(req *s3.DeleteObjectInput) (*s3.DeleteObjectOutput, error) {
	f.DeleteInputs = append(f.DeleteInputs, *req)
	resp := f.DeleteOutputs[0]
	f.DeleteOutputs = f.DeleteOutputs[1:]
	return &resp, nil
}

func (f *FakeS3) PutObject(req *s3.PutObjectInput) (*s3.PutObjectOutput, error) {
	f.PutInputs = append(f.PutInputs, *req)
	resp := f.PutOutputs[0]
	f.PutOutputs = f.PutOutputs[1:]
	return &resp, nil
}

func (f *FakeS3) GetObject(req *s3.GetObjectInput) (*s3.GetObjectOutput, error) {
	f.GetInputs = append(f.GetInputs, *req)
	resp := f.GetOutputs[0]
	f.GetOutputs = f.GetOutputs[1:]
	return &resp, nil
}
