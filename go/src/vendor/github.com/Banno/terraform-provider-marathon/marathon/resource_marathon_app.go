package marathon

import (
	"errors"
	"fmt"
	"log"
	"reflect"
	"strconv"
	"time"

	"github.com/gambol99/go-marathon"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceMarathonApp() *schema.Resource {
	return &schema.Resource{
		Create: resourceMarathonAppCreate,
		Read:   resourceMarathonAppRead,
		Update: resourceMarathonAppUpdate,
		Delete: resourceMarathonAppDelete,

		Schema: map[string]*schema.Schema{
			"accepted_resource_roles": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Schema{
					Type: schema.TypeString,
				},
			},
			"app_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: false,
			},
			"args": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Schema{
					Type: schema.TypeString,
				},
			},
			"backoff_seconds": &schema.Schema{
				Type:     schema.TypeFloat,
				Optional: true,
				ForceNew: false,
				Default:  1,
			},
			"backoff_factor": &schema.Schema{
				Type:     schema.TypeFloat,
				Optional: true,
				ForceNew: false,
				Default:  1.15,
			},
			"cmd": &schema.Schema{
				Type:     schema.TypeString,
				Optional: true,
				ForceNew: false,
			},
			"constraints": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"constraint": &schema.Schema{
							Type:     schema.TypeList,
							Optional: true,
							ForceNew: false,
							Elem: &schema.Resource{
								Schema: map[string]*schema.Schema{
									"attribute": &schema.Schema{
										Type:     schema.TypeString,
										Optional: true,
									},
									"operation": &schema.Schema{
										Type:     schema.TypeString,
										Optional: true,
									},
									"parameter": &schema.Schema{
										Type:     schema.TypeString,
										Optional: true,
									},
								},
							},
						},
					},
				},
			},
			"container": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"docker": &schema.Schema{
							Type:     schema.TypeList,
							Optional: true,
							Elem: &schema.Resource{
								Schema: map[string]*schema.Schema{
									"force_pull_image": &schema.Schema{
										Type:     schema.TypeBool,
										Optional: true,
									},
									"image": &schema.Schema{
										Type:     schema.TypeString,
										Required: true,
									},
									"network": &schema.Schema{
										Type:     schema.TypeString,
										Default:  "HOST",
										Optional: true,
									},
									"parameters": &schema.Schema{
										Type:     schema.TypeList,
										Optional: true,
										ForceNew: false,
										Elem: &schema.Resource{
											Schema: map[string]*schema.Schema{
												"parameter": &schema.Schema{
													Type:     schema.TypeList,
													Optional: true,
													ForceNew: false,
													Elem: &schema.Resource{
														Schema: map[string]*schema.Schema{
															"key": &schema.Schema{
																Type:     schema.TypeString,
																Default:  "tcp",
																Optional: true,
															},
															"value": &schema.Schema{
																Type:     schema.TypeString,
																Default:  "tcp",
																Optional: true,
															},
														},
													},
												},
											},
										},
									},
									"privileged": &schema.Schema{
										Type:     schema.TypeBool,
										Optional: true,
									},
									"port_mappings": &schema.Schema{
										Type:     schema.TypeList,
										Optional: true,
										ForceNew: false,
										Elem: &schema.Resource{
											Schema: map[string]*schema.Schema{
												"port_mapping": &schema.Schema{
													Type:     schema.TypeList,
													Optional: true,
													ForceNew: false,
													Elem: &schema.Resource{
														Schema: map[string]*schema.Schema{
															"container_port": &schema.Schema{
																Type:     schema.TypeInt,
																Optional: true,
															},
															"host_port": &schema.Schema{
																Type:     schema.TypeInt,
																Optional: true,
															},
															"service_port": &schema.Schema{
																Type:     schema.TypeInt,
																Optional: true,
															},
															"protocol": &schema.Schema{
																Type:     schema.TypeString,
																Default:  "tcp",
																Optional: true,
															},
														},
													},
												},
											},
										},
									},
								},
							},
						},
						"volumes": &schema.Schema{
							Type:     schema.TypeList,
							Optional: true,
							ForceNew: false,
							Elem: &schema.Resource{
								Schema: map[string]*schema.Schema{
									"volume": &schema.Schema{
										Type:     schema.TypeList,
										Optional: true,
										ForceNew: false,
										Elem: &schema.Resource{
											Schema: map[string]*schema.Schema{
												"container_path": &schema.Schema{
													Type:     schema.TypeString,
													Optional: true,
												},
												"host_path": &schema.Schema{
													Type:     schema.TypeString,
													Optional: true,
												},
												"mode": &schema.Schema{
													Type:     schema.TypeString,
													Optional: true,
												},
											},
										},
									},
								},
							},
						},
						"type": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
							Default:  "DOCKER",
						},
					},
				},
			},
			"cpus": &schema.Schema{
				Type:     schema.TypeFloat,
				Optional: true,
				Default:  0.1,
				ForceNew: false,
			},
			"dependencies": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Schema{
					Type: schema.TypeString,
				},
			},
			"env": &schema.Schema{
				Type:     schema.TypeMap,
				Optional: true,
				ForceNew: false,
			},
			"fetch": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"uri": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},
						"cache": &schema.Schema{
							Type:     schema.TypeBool,
							Optional: true,
							Default:  false,
						},
						"executable": &schema.Schema{
							Type:     schema.TypeBool,
							Optional: true,
							Default:  false,
						},
						"extract": &schema.Schema{
							Type:     schema.TypeBool,
							Optional: true,
							Default:  false,
						},
					},
				},
			},
			"health_checks": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"health_check": &schema.Schema{
							Type:     schema.TypeList,
							Optional: true,
							ForceNew: false,
							Elem: &schema.Resource{
								Schema: map[string]*schema.Schema{
									"protocol": &schema.Schema{
										Type:     schema.TypeString,
										Default:  "HTTP",
										Optional: true,
									},
									"path": &schema.Schema{
										Type:     schema.TypeString,
										Default:  "/",
										Optional: true,
									},
									"grace_period_seconds": &schema.Schema{
										Type:     schema.TypeInt,
										Default:  300,
										Optional: true,
									},
									"interval_seconds": &schema.Schema{
										Type:     schema.TypeInt,
										Default:  60,
										Optional: true,
									},
									"port_index": &schema.Schema{
										Type:     schema.TypeInt,
										Default:  0,
										Optional: true,
									},
									"timeout_seconds": &schema.Schema{
										Type:     schema.TypeInt,
										Default:  20,
										Optional: true,
									},
									// "ignore_http_1xx": &schema.Schema{
									// 	Type:     schema.TypeBool,
									// 	Optional: true,
									// },
									"max_consecutive_failures": &schema.Schema{
										Type:     schema.TypeInt,
										Default:  3,
										Optional: true,
									},
									"command": &schema.Schema{
										Type:     schema.TypeList,
										Optional: true,
										ForceNew: false,
										Elem: &schema.Resource{
											Schema: map[string]*schema.Schema{
												"value": &schema.Schema{
													Type:     schema.TypeString,
													Optional: true,
												},
											},
										},
									},
									// incomplete computed values here
								},
							},
						},
					},
				},
			},
			"instances": &schema.Schema{
				Type:     schema.TypeInt,
				Optional: true,
				Default:  1,
				ForceNew: false,
			},
			"labels": &schema.Schema{
				Type:     schema.TypeMap,
				Optional: true,
				ForceNew: false,
			},
			"mem": &schema.Schema{
				Type:     schema.TypeFloat,
				Optional: true,
				Default:  128,
				ForceNew: false,
			},
			"ports": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Schema{
					Type: schema.TypeInt,
				},
			},
			"require_ports": &schema.Schema{
				Type:     schema.TypeBool,
				Optional: true,
				Default:  false,
				ForceNew: false,
			},
			"upgrade_strategy": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"minimum_health_capacity": &schema.Schema{
							Type:     schema.TypeFloat,
							Optional: true,
							Default:  1.0,
						},
						"maximum_over_capacity": &schema.Schema{
							Type:     schema.TypeFloat,
							Optional: true,
							Default:  1.0,
						},
					},
				},
			},
			"uris": &schema.Schema{
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: false,
				Elem: &schema.Schema{
					Type: schema.TypeString,
				},
			},
			"version": &schema.Schema{
				Type:     schema.TypeString,
				Computed: true,
			},
			// many other "computed" values haven't been added.
		},
	}
}

type deploymentEvent struct {
	id    string
	state string
}

func readDeploymentEvents(meta *marathon.Marathon, c chan deploymentEvent, ready chan bool) error {
	client := *meta

	EventIDs := marathon.EventIDDeploymentSuccess | marathon.EventIDDeploymentFailed

	events, err := client.AddEventsListener(EventIDs)
	if err != nil {
		log.Fatalf("Failed to register for events, %s", err)
	}
	defer client.RemoveEventsListener(events)
	defer close(c)
	ready <- true

	for {
		select {
		case event := <-events:
			switch mEvent := event.Event.(type) {
			case *marathon.EventDeploymentSuccess:
				c <- deploymentEvent{mEvent.ID, event.Name}
			case *marathon.EventDeploymentFailed:
				c <- deploymentEvent{mEvent.ID, event.Name}
			}
		}
	}
}

func waitOnSuccessfulDeployment(c chan deploymentEvent, id string, timeout time.Duration) error {
	select {
	case dEvent := <-c:
		if dEvent.id == id {
			switch dEvent.state {
			case "deployment_success":
				return nil
			case "deployment_failed":
				return errors.New("Received deployment_failed event from marathon")
			}
		}
	case <-time.After(timeout):
		return errors.New("Deployment timeout reached. Did not receive any deployment events")
	}
	return nil
}

func resourceMarathonAppCreate(d *schema.ResourceData, meta interface{}) error {
	config := meta.(config)
	client := config.Client

	c := make(chan deploymentEvent, 100)
	ready := make(chan bool)
	go readDeploymentEvents(&client, c, ready)
	select {
	case <-ready:
	case <-time.After(60 * time.Second):
		return errors.New("Timeout getting an EventListener")
	}

	application := mutateResourceToApplication(d)

	application, err := client.CreateApplication(application)
	if err != nil {
		log.Println("[ERROR] creating application", err)
		return err
	}
	d.Partial(true)
	d.SetId(application.ID)
	setSchemaFieldsForApp(application, d)

	for _, deploymentID := range application.DeploymentIDs() {
		err = waitOnSuccessfulDeployment(c, deploymentID.DeploymentID, config.DefaultDeploymentTimeout)
		if err != nil {
			log.Println("[ERROR] waiting for application for deployment", deploymentID, err)
			return err
		}
	}

	d.Partial(false)

	return resourceMarathonAppRead(d, meta)
}

func resourceMarathonAppRead(d *schema.ResourceData, meta interface{}) error {
	config := meta.(config)
	client := config.Client

	app, err := client.Application(d.Id())

	if err != nil {
		// Handle a deleted app
		if apiErr, ok := err.(*marathon.APIError); ok && apiErr.ErrCode == marathon.ErrCodeNotFound {
			d.SetId("")
			return nil
		}
		return err
	}

	if app != nil && app.ID == "" {
		d.SetId("")
	}

	if app != nil {
		setSchemaFieldsForApp(app, d)
	}

	return nil
}

func setSchemaFieldsForApp(app *marathon.Application, d *schema.ResourceData) {

	d.Set("app_id", app.ID)
	d.SetPartial("app_id")

	d.Set("accepted_resource_roles", &app.AcceptedResourceRoles)
	d.SetPartial("accepted_resource_roles")

	d.Set("args", app.Args)
	d.SetPartial("args")

	d.Set("backoff_seconds", app.BackoffSeconds)
	d.SetPartial("backoff_seconds")

	d.Set("backoff_factor", app.BackoffFactor)
	d.SetPartial("backoff_factor")

	d.Set("cmd", app.Cmd)
	d.SetPartial("cmd")

	if app.Constraints != nil && len(*app.Constraints) > 0 {
		cMaps := make([]map[string]string, len(*app.Constraints))
		for idx, constraint := range *app.Constraints {
			cMap := make(map[string]string)
			cMap["attribute"] = constraint[0]
			cMap["operation"] = constraint[1]
			if len(constraint) > 2 {
				cMap["parameter"] = constraint[2]
			}
			cMaps[idx] = cMap
		}
		constraints := []interface{}{map[string]interface{}{"constraint": cMaps}}
		d.Set("constraints", constraints)
	} else {
		d.Set("constraints", nil)
	}
	d.SetPartial("constraints")

	if app.Container != nil {
		container := app.Container

		containerMap := make(map[string]interface{})
		containerMap["type"] = container.Type

		if container.Type == "DOCKER" {
			docker := container.Docker
			dockerMap := make(map[string]interface{})
			containerMap["docker"] = []interface{}{dockerMap}

			dockerMap["image"] = docker.Image
			dockerMap["force_pull_image"] = docker.ForcePullImage
			dockerMap["network"] = docker.Network
			parameters := make([]map[string]string, len(*docker.Parameters))
			for idx, p := range *docker.Parameters {
				parameter := make(map[string]string, 2)
				parameter["key"] = p.Key
				parameter["value"] = p.Value
				parameters[idx] = parameter
			}
			dockerMap["parameters"] = parameters
			dockerMap["privileged"] = docker.Privileged

			if docker.PortMappings != nil && len(*docker.PortMappings) > 0 {
				portMappings := make([]map[string]interface{}, len(*docker.PortMappings))
				for idx, portMapping := range *docker.PortMappings {
					pmMap := make(map[string]interface{})
					pmMap["container_port"] = portMapping.ContainerPort
					pmMap["host_port"] = portMapping.HostPort
					// pmMap["service_port"] = portMapping.ServicePort
					pmMap["protocol"] = portMapping.Protocol
					portMappings[idx] = pmMap
				}
				dockerMap["port_mappings"] = []interface{}{map[string]interface{}{"port_mapping": portMappings}}
			} else {
				dockerMap["port_mappings"] = make([]interface{}, 0)
			}

		}

		if len(*container.Volumes) > 0 {
			volumes := make([]map[string]interface{}, len(*container.Volumes))
			for idx, volume := range *container.Volumes {
				volumeMap := make(map[string]interface{})
				volumeMap["container_path"] = volume.ContainerPath
				volumeMap["host_path"] = volume.HostPath
				volumeMap["mode"] = volume.Mode
				volumes[idx] = volumeMap
			}
			containerMap["volumes"] = []interface{}{map[string]interface{}{"volume": volumes}}
		} else {
			containerMap["volumes"] = make([]interface{}, 0)
		}

		d.Set("container", &[]interface{}{containerMap})
	}
	d.SetPartial("container")

	d.Set("cpus", app.CPUs)
	d.SetPartial("cpus")

	d.Set("dependencies", &app.Dependencies)
	d.SetPartial("dependencies")

	d.Set("env", app.Env)
	d.SetPartial("env")

	d.Set("fetch", app.Fetch)
	d.SetPartial("fetch")

	if app.Fetch != nil && len(*app.Fetch) > 0 {
		fetches := make([]map[string]interface{}, len(*app.Fetch))
		for i, fetch := range *app.Fetch {
			fetches[i] = map[string]interface{}{
				"uri":        fetch.URI,
				"cache":      fetch.Cache,
				"executable": fetch.Executable,
				"extract":    fetch.Extract,
			}
		}
		d.Set("fetch", &[]interface{}{fetches})
	} else {
		d.Set("fetch", nil)
	}

	d.SetPartial("fetch")

	if app.HealthChecks != nil && len(*app.HealthChecks) > 0 {
		healthChecks := make([]map[string]interface{}, len(*app.HealthChecks))
		for idx, healthCheck := range *app.HealthChecks {
			hMap := make(map[string]interface{})
			if healthCheck.Command != nil {
				hMap["command"] = []interface{}{map[string]string{"value": healthCheck.Command.Value}}
			}
			hMap["grace_period_seconds"] = healthCheck.GracePeriodSeconds
			hMap["interval_seconds"] = healthCheck.IntervalSeconds
			hMap["max_consecutive_failures"] = healthCheck.MaxConsecutiveFailures
			hMap["path"] = healthCheck.Path
			hMap["port_index"] = healthCheck.PortIndex
			hMap["protocol"] = healthCheck.Protocol
			hMap["timeout_seconds"] = healthCheck.TimeoutSeconds
			healthChecks[idx] = hMap
		}
		d.Set("health_checks", &[]interface{}{map[string]interface{}{"health_check": healthChecks}})
	} else {
		d.Set("health_checks", nil)
	}

	d.SetPartial("health_checks")

	d.Set("instances", app.Instances)
	d.SetPartial("instances")

	d.Set("labels", app.Labels)
	d.SetPartial("labels")

	d.Set("mem", app.Mem)
	d.SetPartial("mem")

	if givenFreePortsDoesNotEqualAllocated(d, app) {
		d.Set("ports", app.Ports)
	}
	d.SetPartial("ports")

	d.Set("require_ports", app.RequirePorts)
	d.SetPartial("require_ports")

	if app.UpgradeStrategy != nil {
		usMap := make(map[string]interface{})
		usMap["minimum_health_capacity"] = app.UpgradeStrategy.MinimumHealthCapacity
		usMap["maximum_over_capacity"] = app.UpgradeStrategy.MaximumOverCapacity
		d.Set("upgrade_strategy", &[]interface{}{usMap})
	} else {
		d.Set("upgrade_strategy", nil)
	}
	d.SetPartial("upgrade_strategy")

	d.Set("uris", app.Uris)
	d.SetPartial("uris")

	// App
	d.Set("executor", app.Executor)
	d.SetPartial("executor")

	d.Set("disk", app.Disk)
	d.SetPartial("disk")

	d.Set("user", app.User)
	d.SetPartial("user")

	d.Set("version", app.Version)
	d.SetPartial("version")

}

func givenFreePortsDoesNotEqualAllocated(d *schema.ResourceData, app *marathon.Application) bool {
	marathonPorts := make([]int, len(app.Ports))
	for i, port := range app.Ports {
		if port >= 10000 && port <= 20000 {
			marathonPorts[i] = 0
		} else {
			marathonPorts[i] = port
		}
	}

	ports := getPorts(d)

	return !reflect.DeepEqual(marathonPorts, ports)
}

func resourceMarathonAppUpdate(d *schema.ResourceData, meta interface{}) error {
	config := meta.(config)
	client := config.Client

	c := make(chan deploymentEvent, 100)
	ready := make(chan bool)
	go readDeploymentEvents(&client, c, ready)
	select {
	case <-ready:
	case <-time.After(60 * time.Second):
		return errors.New("Timeout getting an EventListener")
	}

	application := mutateResourceToApplication(d)

	deploymentID, err := client.UpdateApplication(application, false)
	if err != nil {
		return err
	}

	err = waitOnSuccessfulDeployment(c, deploymentID.DeploymentID, config.DefaultDeploymentTimeout)
	return err
}

func resourceMarathonAppDelete(d *schema.ResourceData, meta interface{}) error {
	config := meta.(config)
	client := config.Client

	deploymentID, err := client.DeleteApplication(d.Id(), false)
	if err != nil {
		return err
	}
	err = client.WaitOnDeployment(deploymentID.DeploymentID, config.DefaultDeploymentTimeout)
	return err
}

func mutateResourceToApplication(d *schema.ResourceData) *marathon.Application {

	application := new(marathon.Application)

	if v, ok := d.GetOk("accepted_resource_roles.#"); ok {
		acceptedResourceRoles := make([]string, v.(int))

		for i := range acceptedResourceRoles {
			acceptedResourceRoles[i] = d.Get("accepted_resource_roles." + strconv.Itoa(i)).(string)
		}

		if len(acceptedResourceRoles) != 0 {
			application.AcceptedResourceRoles = acceptedResourceRoles
		}
	}

	if v, ok := d.GetOk("app_id"); ok {
		application.ID = v.(string)
	}

	if v, ok := d.GetOk("args.#"); ok {
		args := make([]string, v.(int))

		for i := range args {
			args[i] = d.Get("args." + strconv.Itoa(i)).(string)
		}

		if len(args) != 0 {
			application.Args = &args
		}
	}

	if v, ok := d.GetOk("backoff_seconds"); ok {
		value := v.(float64)
		application.BackoffSeconds = &value
	}

	if v, ok := d.GetOk("backoff_factor"); ok {
		value := v.(float64)
		application.BackoffFactor = &value
	}

	if v, ok := d.GetOk("cmd"); ok {
		value := v.(string)
		application.Cmd = &value
	}

	if v, ok := d.GetOk("constraints.0.constraint.#"); ok {
		constraints := make([][]string, v.(int))

		for i := range constraints {
			cMap := d.Get(fmt.Sprintf("constraints.0.constraint.%d", i)).(map[string]interface{})

			if cMap["parameter"] == "" {
				constraints[i] = make([]string, 2)
				constraints[i][0] = cMap["attribute"].(string)
				constraints[i][1] = cMap["operation"].(string)
			} else {
				constraints[i] = make([]string, 3)
				constraints[i][0] = cMap["attribute"].(string)
				constraints[i][1] = cMap["operation"].(string)
				constraints[i][2] = cMap["parameter"].(string)
			}
		}

		application.Constraints = &constraints
	} else {
		application.Constraints = nil
	}

	if v, ok := d.GetOk("container.0.type"); ok {
		container := new(marathon.Container)
		t := v.(string)

		container.Type = t

		if t == "DOCKER" {
			docker := new(marathon.Docker)

			if v, ok := d.GetOk("container.0.docker.0.image"); ok {
				docker.Image = v.(string)
			}

			if v, ok := d.GetOk("container.0.docker.0.force_pull_image"); ok {
				value := v.(bool)
				docker.ForcePullImage = &value
			}

			if v, ok := d.GetOk("container.0.docker.0.network"); ok {
				docker.Network = v.(string)
			}

			if v, ok := d.GetOk("container.0.docker.0.parameters.0.parameter.#"); ok {
				for i := 0; i < v.(int); i++ {
					paramMap := d.Get(fmt.Sprintf("container.0.docker.0.parameters.0.parameter.%d", i)).(map[string]interface{})
					docker.AddParameter(paramMap["key"].(string), paramMap["value"].(string))
				}
			}

			if v, ok := d.GetOk("container.0.docker.0.privileged"); ok {
				value := v.(bool)
				docker.Privileged = &value
			}

			if v, ok := d.GetOk("container.0.docker.0.port_mappings.0.port_mapping.#"); ok {
				portMappings := make([]marathon.PortMapping, v.(int))

				for i := range portMappings {
					portMapping := new(marathon.PortMapping)
					portMappings[i] = *portMapping

					pmMap := d.Get(fmt.Sprintf("container.0.docker.0.port_mappings.0.port_mapping.%d", i)).(map[string]interface{})

					if val, ok := pmMap["container_port"]; ok {
						portMappings[i].ContainerPort = val.(int)
					}
					if val, ok := pmMap["host_port"]; ok {
						portMappings[i].HostPort = val.(int)
					}
					if val, ok := pmMap["protocol"]; ok {
						portMappings[i].Protocol = val.(string)
					}
					if val, ok := pmMap["service_port"]; ok {
						portMappings[i].ServicePort = val.(int)
					}

				}
				docker.PortMappings = &portMappings
			}
			container.Docker = docker

		}

		if v, ok := d.GetOk("container.0.volumes.0.volume.#"); ok {
			volumes := make([]marathon.Volume, v.(int))

			for i := range volumes {
				volume := new(marathon.Volume)
				volumes[i] = *volume

				volumeMap := d.Get(fmt.Sprintf("container.0.volumes.0.volume.%d", i)).(map[string]interface{})

				if val, ok := volumeMap["container_path"]; ok {
					volumes[i].ContainerPath = val.(string)
				}
				if val, ok := volumeMap["host_path"]; ok {
					volumes[i].HostPath = val.(string)
				}
				if val, ok := volumeMap["mode"]; ok {
					volumes[i].Mode = val.(string)
				}
			}
			container.Volumes = &volumes
		}

		application.Container = container
	}

	if v, ok := d.GetOk("cpus"); ok {
		application.CPUs = v.(float64)
	}

	if v, ok := d.GetOk("dependencies.#"); ok {
		dependencies := make([]string, v.(int))

		for i := range dependencies {
			dependencies[i] = d.Get("dependencies." + strconv.Itoa(i)).(string)
		}

		if len(dependencies) != 0 {
			application.Dependencies = dependencies
		}
	}

	if v, ok := d.GetOk("env"); ok {
		envMap := v.(map[string]interface{})
		env := make(map[string]string, len(envMap))

		for k, v := range envMap {
			env[k] = v.(string)
		}

		application.Env = &env
	} else {
		env := make(map[string]string, 0)
		application.Env = &env
	}

	if v, ok := d.GetOk("fetch.#"); ok {
		fetch := make([]marathon.Fetch, v.(int))

		for i := range fetch {
			fetchMap := d.Get(fmt.Sprintf("fetch.%d", i)).(map[string]interface{})

			if val, ok := fetchMap["uri"].(string); ok {
				fetch[i].URI = val
			}
			if val, ok := fetchMap["cache"].(bool); ok {
				fetch[i].Cache = val
			}
			if val, ok := fetchMap["executable"].(bool); ok {
				fetch[i].Executable = val
			}
			if val, ok := fetchMap["extract"].(bool); ok {
				fetch[i].Extract = val
			}
		}

		application.Fetch = &fetch
	} else {
		application.Fetch = nil
	}

	if v, ok := d.GetOk("health_checks.0.health_check.#"); ok {
		healthChecks := make([]marathon.HealthCheck, v.(int))

		for i := range healthChecks {
			healthCheck := new(marathon.HealthCheck)
			mapStruct := d.Get("health_checks.0.health_check." + strconv.Itoa(i)).(map[string]interface{})

			commands := mapStruct["command"].([]interface{})
			if len(commands) > 0 {
				commandMap := commands[0].(map[string]interface{})
				healthCheck.Command = &marathon.Command{Value: commandMap["value"].(string)}
				healthCheck.Protocol = "COMMAND"
				path := ""
				healthCheck.Path = &path
			} else {
				if prop, ok := mapStruct["path"]; ok {
					prop := prop.(string)
					healthCheck.Path = &prop
				}

				if prop, ok := mapStruct["port_index"]; ok {
					prop := prop.(int)
					healthCheck.PortIndex = &prop
				}

				if prop, ok := mapStruct["protocol"]; ok {
					healthCheck.Protocol = prop.(string)
				}
			}

			if prop, ok := mapStruct["timeout_seconds"]; ok {
				healthCheck.TimeoutSeconds = prop.(int)
			}

			if prop, ok := mapStruct["grace_period_seconds"]; ok {
				healthCheck.GracePeriodSeconds = prop.(int)
			}

			if prop, ok := mapStruct["interval_seconds"]; ok {
				healthCheck.IntervalSeconds = prop.(int)
			}

			if prop, ok := mapStruct["max_consecutive_failures"]; ok {
				prop := prop.(int)
				healthCheck.MaxConsecutiveFailures = &prop
			}

			healthChecks[i] = *healthCheck
		}

		application.HealthChecks = &healthChecks
	} else {
		application.HealthChecks = nil
	}

	if v, ok := d.GetOk("instances"); ok {
		v := v.(int)
		application.Instances = &v
	}

	if v, ok := d.GetOk("labels"); ok {
		labelsMap := v.(map[string]interface{})
		labels := make(map[string]string, len(labelsMap))

		for k, v := range labelsMap {
			labels[k] = v.(string)
		}

		application.Labels = &labels
	} else {
		labels := make(map[string]string, 0)
		application.Labels = &labels
	}

	if v, ok := d.GetOk("mem"); ok {
		v := v.(float64)
		application.Mem = &v
	}

	if v, ok := d.GetOk("require_ports"); ok {
		v := v.(bool)
		application.RequirePorts = &v
	}

	application.Ports = getPorts(d)

	upgradeStrategy := &marathon.UpgradeStrategy{}

	if v, ok := d.GetOk("upgrade_strategy.0.minimum_health_capacity"); ok {
		upgradeStrategy.MinimumHealthCapacity = v.(float64)
	}

	if v, ok := d.GetOk("upgrade_strategy.0.maximum_over_capacity"); ok {
		upgradeStrategy.MaximumOverCapacity = v.(float64)
	}

	application.UpgradeStrategy = upgradeStrategy

	if v, ok := d.GetOk("uris.#"); ok {
		uris := make([]string, v.(int))

		for i := range uris {
			uris[i] = d.Get("uris." + strconv.Itoa(i)).(string)
		}

		if len(uris) != 0 {
			application.Uris = &uris
		}
	}

	return application
}

func getPorts(d *schema.ResourceData) []int {
	var ports []int
	if v, ok := d.GetOk("ports.#"); ok {
		ports = make([]int, v.(int))

		for i := range ports {
			ports[i] = d.Get("ports." + strconv.Itoa(i)).(int)
		}
	}
	return ports
}
