package services

const (
	triggerData = `{
    "messages": [
        {
            "type": "incident.trigger",
            "data": {
                "incident": {
                    "id": "PIVD27N",
                    "incident_number": 8,
                    "created_on": "2015-08-26T11:29:00Z",
                    "status": "triggered",
                    "pending_actions": [
                        {
                            "type": "resolve",
                            "at": "2015-08-26T18:29:00+03:00"
                        }
                    ],
                    "html_url": "https://koding-test.pagerduty.com/incidents/PIVD27N",
                    "incident_key": "ff880a34f36c4f72a602a9b02e0ab8a6",
                    "service": {
                        "id": "P1QP2YT",
                        "name": "Datadog Service",
                        "html_url": "https://koding-test.pagerduty.com/services/P1QP2YT",
                        "deleted_at": null,
                        "description": "This service was created during onboarding on August 25, 2015."
                    },
                    "escalation_policy": {
                        "id": "P3OQXAP",
                        "name": "Default",
                        "deleted_at": null
                    },
                    "assigned_to_user": {
                        "id": "PWGTT51",
                        "name": "Mehmet Ali",
                        "email": "mehmet@koding.com",
                        "html_url": "https://koding-test.pagerduty.com/users/PWGTT51"
                    },
                    "trigger_summary_data": {
                        "subject": "datadesc"
                    },
                    "trigger_details_html_url": "https://koding-test.pagerduty.com/incidents/PIVD27N/log_entries/Q1FPWA7BWVRZZS",
                    "trigger_type": "web_trigger",
                    "last_status_change_on": "2015-08-26T11:29:00Z",
                    "last_status_change_by": null,
                    "number_of_escalations": 0,
                    "assigned_to": [
                        {
                            "at": "2015-08-26T11:29:00Z",
                            "object": {
                                "id": "PWGTT51",
                                "name": "Mehmet Ali",
                                "email": "mehmet@koding.com",
                                "html_url": "https://koding-test.pagerduty.com/users/PWGTT51",
                                "type": "user"
                            }
                        }
                    ]
                }
            },
            "id": "a6984860-4be5-11e5-a48e-22000ae31361",
            "created_on": "2015-08-26T11:29:00Z"
        }
    ]
}`

	resolveData = `{
    "messages": [
        {
            "type": "incident.resolve",
            "data": {
                "incident": {
                    "id": "PWVXHR6",
                    "incident_number": 9,
                    "created_on": "2015-08-26T11:29:15Z",
                    "status": "resolved",
                    "pending_actions": [],
                    "html_url": "https://koding-test.pagerduty.com/incidents/PWVXHR6",
                    "incident_key": "260a261e2d4c45548741a0df94ddc21d",
                    "service": {
                        "id": "POJ7I2R",
                        "name": "amazon",
                        "html_url": "https://koding-test.pagerduty.com/services/POJ7I2R",
                        "deleted_at": null,
                        "description": ""
                    },
                    "escalation_policy": {
                        "id": "P3OQXAP",
                        "name": "Default",
                        "deleted_at": null
                    },
                    "assigned_to_user": null,
                    "trigger_summary_data": {
                        "subject": "amadesc"
                    },
                    "trigger_details_html_url": "https://koding-test.pagerduty.com/incidents/PWVXHR6/log_entries/Q3QJA420ALZK16",
                    "trigger_type": "web_trigger",
                    "last_status_change_on": "2015-08-26T11:30:54Z",
                    "last_status_change_by": {
                        "id": "PWGTT51",
                        "name": "Mehmet Ali",
                        "email": "mehmet@koding.com",
                        "html_url": "https://koding-test.pagerduty.com/users/PWGTT51"
                    },
                    "number_of_escalations": 0,
                    "resolved_by_user": {
                        "id": "PWGTT51",
                        "name": "Mehmet Ali",
                        "email": "mehmet@koding.com",
                        "html_url": "https://koding-test.pagerduty.com/users/PWGTT51"
                    },
                    "assigned_to": []
                }
            },
            "id": "eaaf7730-4be5-11e5-a7d3-22000ad9bf74",
            "created_on": "2015-08-26T11:30:54Z"
        }
    ]
}`

	unacknowledgeData = `{
    "messages": [
        {
            "type": "incident.unacknowledge",
            "data": {
                "incident": {
                    "id": "PD0MLVP",
                    "incident_number": 7,
                    "created_on": "2015-08-26T11:21:38Z",
                    "status": "triggered",
                    "pending_actions": [
                        {
                            "type": "resolve",
                            "at": "2015-08-26T18:21:38+03:00"
                        }
                    ],
                    "html_url": "https://koding-test.pagerduty.com/incidents/PD0MLVP",
                    "incident_key": "44bea906722f48d3b893fffea956dda7",
                    "service": {
                        "id": "POJ7I2R",
                        "name": "amazon",
                        "html_url": "https://koding-test.pagerduty.com/services/POJ7I2R",
                        "deleted_at": null,
                        "description": ""
                    },
                    "escalation_policy": {
                        "id": "P3OQXAP",
                        "name": "Default",
                        "deleted_at": null
                    },
                    "assigned_to_user": {
                        "id": "PWGTT51",
                        "name": "Mehmet Ali",
                        "email": "mehmet@koding.com",
                        "html_url": "https://koding-test.pagerduty.com/users/PWGTT51"
                    },
                    "trigger_summary_data": {
                        "subject": "amazon desc."
                    },
                    "trigger_details_html_url": "https://koding-test.pagerduty.com/incidents/PD0MLVP/log_entries/Q3PFIWS6WGDMDG",
                    "trigger_type": "web_trigger",
                    "last_status_change_on": "2015-08-26T11:56:11Z",
                    "last_status_change_by": null,
                    "number_of_escalations": 0,
                    "assigned_to": [
                        {
                            "at": "2015-08-26T11:21:38Z",
                            "object": {
                                "id": "PWGTT51",
                                "name": "Mehmet Ali",
                                "email": "mehmet@koding.com",
                                "html_url": "https://koding-test.pagerduty.com/users/PWGTT51",
                                "type": "user"
                            }
                        }
                    ]
                }
            },
            "id": "728fd480-4be9-11e5-8ed7-000d3a31cb72",
            "created_on": "2015-08-26T11:56:11Z"
        }
    ]
}`

	acknowledgeData = `{
    "messages": [
        {
            "type": "incident.acknowledge",
            "data": {
                "incident": {
                    "id": "PWVXHR6",
                    "incident_number": 9,
                    "created_on": "2015-08-26T11:29:15Z",
                    "status": "acknowledged",
                    "pending_actions": [
                        {
                            "type": "unacknowledge",
                            "at": "2015-08-26T11:59:24Z"
                        },
                        {
                            "type": "resolve",
                            "at": "2015-08-26T15:29:15Z"
                        }
                    ],
                    "html_url": "https://koding-test.pagerduty.com/incidents/PWVXHR6",
                    "incident_key": "260a261e2d4c45548741a0df94ddc21d",
                    "service": {
                        "id": "POJ7I2R",
                        "name": "amazon",
                        "html_url": "https://koding-test.pagerduty.com/services/POJ7I2R",
                        "deleted_at": null,
                        "description": ""
                    },
                    "escalation_policy": {
                        "id": "P3OQXAP",
                        "name": "Default",
                        "deleted_at": null
                    },
                    "assigned_to_user": {
                        "id": "PWGTT51",
                        "name": "Mehmet Ali",
                        "email": "mehmet@koding.com",
                        "html_url": "https://koding-test.pagerduty.com/users/PWGTT51"
                    },
                    "trigger_summary_data": {
                        "subject": "amadesc"
                    },
                    "trigger_details_html_url": "https://koding-test.pagerduty.com/incidents/PWVXHR6/log_entries/Q3QJA420ALZK16",
                    "trigger_type": "web_trigger",
                    "last_status_change_on": "2015-08-26T11:29:24Z",
                    "last_status_change_by": {
                        "id": "PWGTT51",
                        "name": "Mehmet Ali",
                        "email": "mehmet@koding.com",
                        "html_url": "https://koding-test.pagerduty.com/users/PWGTT51"
                    },
                    "number_of_escalations": 0,
                    "assigned_to": [
                        {
                            "at": "2015-08-26T11:29:15Z",
                            "object": {
                                "id": "PWGTT51",
                                "name": "Mehmet Ali",
                                "email": "mehmet@koding.com",
                                "html_url": "https://koding-test.pagerduty.com/users/PWGTT51",
                                "type": "user"
                            }
                        }
                    ],
                    "acknowledgers": [
                        {
                            "at": "2015-08-26T11:29:24Z",
                            "object": {
                                "id": "PWGTT51",
                                "name": "Mehmet Ali",
                                "email": "mehmet@koding.com",
                                "html_url": "https://koding-test.pagerduty.com/users/PWGTT51",
                                "type": "user"
                            }
                        }
                    ]
                }
            },
            "id": "b4f2e780-4be5-11e5-a48e-22000ae31361",
            "created_on": "2015-08-26T11:29:24Z"
        }
    ]
}`
)
