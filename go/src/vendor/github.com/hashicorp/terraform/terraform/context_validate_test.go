package terraform

import (
	"fmt"
	"strings"
	"testing"
)

func TestContext2Validate_badVar(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-bad-var")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_varNoDefaultExplicitType(t *testing.T) {
	m := testModule(t, "validate-var-no-default-explicit-type")
	c := testContext2(t, &ContextOpts{
		Module: m,
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_computedVar(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-computed-var")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws":  testProviderFuncFixed(p),
			"test": testProviderFuncFixed(testProvider("test")),
		},
	})

	p.ValidateFn = func(c *ResourceConfig) ([]string, []error) {
		if !c.IsComputed("value") {
			return nil, []error{fmt.Errorf("value isn't computed")}
		}

		return nil, c.CheckSet([]string{"value"})
	}

	p.ConfigureFn = func(c *ResourceConfig) error {
		return fmt.Errorf("Configure should not be called for provider")
	}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_countNegative(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-count-negative")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_countVariable(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "apply-count-variable")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_countVariableNoDefault(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-count-variable")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) != 1 {
		t.Fatalf("bad: %s", e)
	}
}

/*
TODO: What should we do here?
func TestContext2Validate_cycle(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-cycle")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("expected no warns, got: %#v", w)
	}
	if len(e) != 1 {
		t.Fatalf("expected 1 err, got: %s", e)
	}
}
*/

func TestContext2Validate_moduleBadOutput(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-bad-module-output")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_moduleGood(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-good-module")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_moduleBadResource(t *testing.T) {
	m := testModule(t, "validate-module-bad-rc")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	p.ValidateResourceReturnErrors = []error{fmt.Errorf("bad")}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_moduleDepsShouldNotCycle(t *testing.T) {
	m := testModule(t, "validate-module-deps-cycle")
	p := testProvider("aws")
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := ctx.Validate()

	if len(w) > 0 {
		t.Fatalf("expected no warnings, got: %s", w)
	}
	if len(e) > 0 {
		t.Fatalf("expected no errors, got: %s", e)
	}
}

func TestContext2Validate_moduleProviderInherit(t *testing.T) {
	m := testModule(t, "validate-module-pc-inherit")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	p.ValidateFn = func(c *ResourceConfig) ([]string, []error) {
		return nil, c.CheckSet([]string{"set"})
	}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_moduleProviderInheritOrphan(t *testing.T) {
	m := testModule(t, "validate-module-pc-inherit-orphan")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		State: &State{
			Modules: []*ModuleState{
				&ModuleState{
					Path: []string{"root", "child"},
					Resources: map[string]*ResourceState{
						"aws_instance.bar": &ResourceState{
							Type: "aws_instance",
							Primary: &InstanceState{
								ID: "bar",
							},
						},
					},
				},
			},
		},
	})

	p.ValidateFn = func(c *ResourceConfig) ([]string, []error) {
		v, ok := c.Get("set")
		if !ok {
			return nil, []error{fmt.Errorf("not set")}
		}
		if v != "bar" {
			return nil, []error{fmt.Errorf("bad: %#v", v)}
		}

		return nil, nil
	}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_moduleProviderVar(t *testing.T) {
	m := testModule(t, "validate-module-pc-vars")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]string{
			"provider_var": "bar",
		},
	})

	p.ValidateFn = func(c *ResourceConfig) ([]string, []error) {
		return nil, c.CheckSet([]string{"foo"})
	}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_moduleProviderInheritUnused(t *testing.T) {
	m := testModule(t, "validate-module-pc-inherit-unused")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	p.ValidateFn = func(c *ResourceConfig) ([]string, []error) {
		return nil, c.CheckSet([]string{"foo"})
	}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_orphans(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-good")
	state := &State{
		Modules: []*ModuleState{
			&ModuleState{
				Path: rootModulePath,
				Resources: map[string]*ResourceState{
					"aws_instance.web": &ResourceState{
						Type: "aws_instance",
						Primary: &InstanceState{
							ID: "bar",
						},
					},
				},
			},
		},
	}
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		State: state,
	})

	p.ValidateResourceFn = func(
		t string, c *ResourceConfig) ([]string, []error) {
		return nil, c.CheckSet([]string{"foo"})
	}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_providerConfig_bad(t *testing.T) {
	m := testModule(t, "validate-bad-pc")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	p.ValidateReturnErrors = []error{fmt.Errorf("bad")}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %s", e)
	}
	if !strings.Contains(fmt.Sprintf("%s", e), "bad") {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_providerConfig_badEmpty(t *testing.T) {
	m := testModule(t, "validate-bad-pc-empty")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	p.ValidateReturnErrors = []error{fmt.Errorf("bad")}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_providerConfig_good(t *testing.T) {
	m := testModule(t, "validate-bad-pc")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_provisionerConfig_bad(t *testing.T) {
	m := testModule(t, "validate-bad-prov-conf")
	p := testProvider("aws")
	pr := testProvisioner()
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Provisioners: map[string]ResourceProvisionerFactory{
			"shell": testProvisionerFuncFixed(pr),
		},
	})

	pr.ValidateReturnErrors = []error{fmt.Errorf("bad")}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_provisionerConfig_good(t *testing.T) {
	m := testModule(t, "validate-bad-prov-conf")
	p := testProvider("aws")
	pr := testProvisioner()
	pr.ValidateFn = func(c *ResourceConfig) ([]string, []error) {
		if c == nil {
			t.Fatalf("missing resource config for provisioner")
		}
		return nil, c.CheckSet([]string{"command"})
	}
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Provisioners: map[string]ResourceProvisionerFactory{
			"shell": testProvisionerFuncFixed(pr),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_requiredVar(t *testing.T) {
	m := testModule(t, "validate-required-var")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_resourceConfig_bad(t *testing.T) {
	m := testModule(t, "validate-bad-rc")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	p.ValidateResourceReturnErrors = []error{fmt.Errorf("bad")}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_resourceConfig_good(t *testing.T) {
	m := testModule(t, "validate-bad-rc")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_resourceNameSymbol(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-resource-name-symbol")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_selfRef(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-self-ref")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_selfRefMulti(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-self-ref-multi")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_selfRefMultiAll(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-self-ref-multi-all")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
	})

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) == 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_tainted(t *testing.T) {
	p := testProvider("aws")
	m := testModule(t, "validate-good")
	state := &State{
		Modules: []*ModuleState{
			&ModuleState{
				Path: rootModulePath,
				Resources: map[string]*ResourceState{
					"aws_instance.foo": &ResourceState{
						Type: "aws_instance",
						Tainted: []*InstanceState{
							&InstanceState{
								ID: "bar",
							},
						},
					},
				},
			},
		},
	}
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		State: state,
	})

	p.ValidateResourceFn = func(
		t string, c *ResourceConfig) ([]string, []error) {
		return nil, c.CheckSet([]string{"foo"})
	}

	w, e := c.Validate()
	if len(w) > 0 {
		t.Fatalf("bad: %#v", w)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %#v", e)
	}
}

func TestContext2Validate_targetedDestroy(t *testing.T) {
	m := testModule(t, "validate-targeted")
	p := testProvider("aws")
	pr := testProvisioner()
	p.ApplyFn = testApplyFn
	p.DiffFn = testDiffFn
	ctx := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Provisioners: map[string]ResourceProvisionerFactory{
			"shell": testProvisionerFuncFixed(pr),
		},
		State: &State{
			Modules: []*ModuleState{
				&ModuleState{
					Path: rootModulePath,
					Resources: map[string]*ResourceState{
						"aws_instance.foo": resourceState("aws_instance", "i-bcd345"),
						"aws_instance.bar": resourceState("aws_instance", "i-abc123"),
					},
				},
			},
		},
		Targets: []string{"aws_instance.foo"},
		Destroy: true,
	})

	w, e := ctx.Validate()
	if len(w) > 0 {
		warnStr := ""
		for _, v := range w {
			warnStr = warnStr + " " + v
		}
		t.Fatalf("bad: %s", warnStr)
	}
	if len(e) > 0 {
		t.Fatalf("bad: %s", e)
	}
}

func TestContext2Validate_varRefFilled(t *testing.T) {
	m := testModule(t, "validate-variable-ref")
	p := testProvider("aws")
	c := testContext2(t, &ContextOpts{
		Module: m,
		Providers: map[string]ResourceProviderFactory{
			"aws": testProviderFuncFixed(p),
		},
		Variables: map[string]string{
			"foo": "bar",
		},
	})

	var value interface{}
	p.ValidateResourceFn = func(t string, c *ResourceConfig) ([]string, []error) {
		value, _ = c.Get("foo")
		return nil, nil
	}

	c.Validate()
	if value != "bar" {
		t.Fatalf("bad: %#v", value)
	}
}
