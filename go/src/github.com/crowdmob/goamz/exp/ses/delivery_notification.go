package ses

import (
	"time"
)

//http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#top-level-json-object
const (
	NOTIFICATION_TYPE_BOUNCE    = "Bounce"
	NOTIFICATION_TYPE_COMPLAINT = "Complaint"
	NOTIFICATION_TYPE_DELIVERY  = "Delivery"

	//http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#bounce-types
	BOUNCE_TYPE_UNDETERMINED           = "Undetermined"
	BOUNCE_TYPE_PERMANENT              = "Permanent"
	BOUNCE_TYPE_TRANSIENT              = "Transient"
	BOUNCE_SUBTYPE_UNDETERMINED        = "Undetermined"
	BOUNCE_SUBTYPE_GENERAL             = "General"
	BOUNCE_SUBTYPE_NO_EMAIL            = "NoEmail"
	BOUNCE_SUBTYPE_SUPPRESSED          = "Suppressed"
	BOUNCE_SUBTYPE_MAILBOX_FULL        = "MailboxFull"
	BOUNCE_SUBTYPE_MESSAGE_TOO_LARGE   = "MessageTooLarge"
	BOUNCE_SUBTYPE_CONTENT_REJECTED    = "ContentRejected"
	BOUNCE_SUBTYPE_ATTACHMENT_REJECTED = "AttachmentRejected"

	// http://www.iana.org/assignments/marf-parameters/marf-parameters.xml#marf-parameters-2
	COMPLAINT_FEEDBACK_TYPE_ABUSE        = "abuse"
	COMPLAINT_FEEDBACK_TYPE_AUTH_FAILURE = "auth-failure"
	COMPLAINT_FEEDBACK_TYPE_FRAUD        = "fraud"
	COMPLAINT_FEEDBACK_TYPE_NOT_SPAM     = "not-spam"
	COMPLAINT_FEEDBACK_TYPE_OTHER        = "other"
	COMPLAINT_FEEDBACK_TYPE_VIRUS        = "virus"
)

type SNSNotification struct {
	NotificationType string     `json:"notificationType"`
	Bounce           *Bounce    `json:"bounce" optional`
	Complaint        *Complaint `json:"complaint" optional`
	Delivery         *Delivery  `json:"delivery" optional`
	Mail             *Mail      `json:"mail"`
}

// Represent the delivery of an email
type Mail struct {
	Timestamp   time.Time `json:"timestamp"`
	MessageId   string    `json:"messageId"`
	Source      string    `json:"source"`
	Destination []string  `json:"destination"`
}

// A bounced recipient
// http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#bounced-recipients
type BouncedRecipient struct {
	EmailAddress   string `json:"emailAddress"`
	Action         string `json:"action"`
	Status         string `json:"status"`
	DiagnosticCode string `json:"diagnosticCode"`
}

// A bounce notifiction object
// http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#bounce-object
type Bounce struct {
	BounceType        string              `json:"bounceType"`
	BounceSubType     string              `json:"bounceSubType"`
	BouncedRecipients []*BouncedRecipient `json:"bouncedRecipients"`
	ReportingMTA      string              `json:"reportingMTA"`
	Timestamp         time.Time           `json:"timestamp"`
	FeedbackId        string              `json:"feedbackId"`
}

// A receipient which complained
// http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#complained-recipients
type ComplainedRecipient struct {
	EmailAddress string `json:"emailAddress"`
}

// A complain notification object
// http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#complaint-object
type Complaint struct {
	UserAgent             string              `json:"userAgent"`
	ComplainedRecipients  []*BouncedRecipient `json:"complainedRecipients"`
	ComplaintFeedbackType string              `json:"complaintFeedbackType"`
	ArrivalDate           time.Time           `json:"arrivalDate"`
	Timestamp             time.Time           `json:"timestamp"`
	FeedbackId            string              `json:"feedbackId"`
}

// A successful delivery
// http://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#delivery-object
type Delivery struct {
	Timestamp            time.Time `json:"timestamp"`
	ProcessingTimeMillis int64     `json:"processingTimeMillis"`
	Recipients           []string  `json:"recipients"`
	SmtpResponse         string    `json:"smtpResponse"`
	ReportingMTA         string    `json:"reportingMTA"`
}
