package app

import "koding/kites/kloud/stack"

type Builder struct {
	Credential *stack.CredentialItem
}

type TemplateOptions struct {
}

func (b *Builder) BuildTemplate(opts *TemplateOptions) error {
	return nil
}

type CredentialOptions struct {
}

func (b *Builder) BuildCredential(opts *CredentialOptions) error {
	return nil
}

type StackOptions struct {
}

func (b *Builder) BuildStack(opts *StackOptions) error {
	return nil
}
