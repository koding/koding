package main

import (
	"fmt"
	"github.com/hsoj/asn1-ber"
	"io"
	"koding/tools/db"
	"koding/tools/utils"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"strconv"
	"strings"
)

func main() {
	utils.Startup("ldapserver", true)

	ln, err := net.Listen("tcp", ":389")
	if err != nil {
		fmt.Println(err)
		return
	}
	for {
		conn, err := ln.Accept()
		if err != nil {
			fmt.Println(err)
			continue
		}
		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	bound := false
	var vm *virt.VM

	for {
		packet, err := ber.ReadPacket(conn)
		if err != nil {
			if err == io.EOF {
				break
			}
			panic(err)
		}

		messageID := packet.Children[0].Value.(uint64)
		request := packet.Children[1]

		switch request.Tag {
		case ApplicationBindRequest:
			name := request.Children[1].Value.(string)
			password := request.Children[2].Data.String()

			if name == "vmhost" && password == "abc" {
				bound = true
			} else if strings.HasPrefix(name, "vm-") && bson.IsObjectIdHex(name[3:]) {
				vm, err = virt.FindVMById(bson.ObjectIdHex(name[3:]))
				bound = (err == nil && password == vm.LdapPassword)
			} else {
				user, err := db.FindUserByName(name)
				bound = (err == nil && user.HasPassword(password))
			}

			if bound {
				conn.Write(createSimpleResponse(messageID, ApplicationBindResponse, LDAPResultSuccess).Bytes())
			} else {
				conn.Write(createSimpleResponse(messageID, ApplicationBindResponse, LDAPResultInvalidCredentials).Bytes())
			}

		case ApplicationUnbindRequest:
			bound = false

		case ApplicationSearchRequest:
			if !bound {
				conn.Write(createSimpleResponse(messageID, ApplicationSearchResultDone, LDAPResultInsufficientAccessRights).Bytes())
				continue
			}

			if !lookupUser(request.Children[6], messageID, vm, conn) {
				// ber.PrintPacket(packet) // for debugging
			}

			conn.Write(createSimpleResponse(messageID, ApplicationSearchResultDone, LDAPResultSuccess).Bytes())

		default:
			panic("Unsupported LDAP command")
		}
	}
}

func lookupUser(filter *ber.Packet, messageID uint64, vm *virt.VM, conn net.Conn) bool {
	switch findAttributeInFilter(filter, "objectClass") {
	case "posixGroup":
		if memberUid := findAttributeInFilter(filter, "memberUid"); memberUid != "" {
			if vm == nil {
				return true
			}

			user, err := db.FindUserByName(memberUid)
			if err != nil {
				return true
			}
			userEntry := vm.GetUserEntry(user)

			if userEntry != nil && userEntry.Sudo {
				conn.Write(createSearchResultEntry(messageID, map[string]string{
					"objectClass": "posixGroup",
					"cn":          "sudo",
					"gidNumber":   "27",
				}).Bytes())
			}

		} else if gidStr := findAttributeInFilter(filter, "gidNumber"); gidStr != "" {
			gid, _ := strconv.Atoi(gidStr)
			user, err := db.FindUserByUid(gid)
			if err != nil || (vm != nil && vm.GetUserEntry(user) == nil) {
				return true
			}

			conn.Write(createSearchResultEntry(messageID, map[string]string{
				"objectClass": "posixGroup",
				"cn":          user.Name,
				"gidNumber":   gidStr,
			}).Bytes())

		} else {
			return false
		}

	default: // including "posixAccount"
		var user *db.User
		var err error
		if name := findAttributeInFilter(filter, "uid"); name != "" {
			user, err = db.FindUserByName(name)
		} else if uidStr := findAttributeInFilter(filter, "uidNumber"); uidStr != "" {
			uid, _ := strconv.Atoi(uidStr)
			user, err = db.FindUserByUid(uid)
		} else {
			return false
		}
		if err != nil || (vm != nil && vm.GetUserEntry(user) == nil) {
			return true
		}

		conn.Write(createSearchResultEntry(messageID, map[string]string{
			"objectClass":   "posixAccount",
			"cn":            user.Name,
			"uid":           user.Name,
			"userPassword":  "{SSHA}MmhmXrqch9NbAcRA6Z79OTSj6MqNXQxF",
			"uidNumber":     strconv.Itoa(user.Uid),
			"gidNumber":     strconv.Itoa(user.Uid),
			"homeDirectory": "/home/" + user.Name,
			"loginShell":    "/bin/bash",
		}).Bytes())

	}

	return true
}

func findAttributeInFilter(filter *ber.Packet, name string) string {
	switch filter.Tag {
	case 0, 1: // and, or
		for _, child := range filter.Children {
			if result := findAttributeInFilter(child, name); result != "" {
				return result
			}
		}
	case 3: // equalityMatch
		if filter.Children[0].Value == name {
			return filter.Children[1].Value.(string)
		}
	}
	return ""
}

func createLDAPMessage(messageID uint64) *ber.Packet {
	packet := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSequence, nil, "LDAPMessage")
	packet.AppendChild(ber.NewInteger(ber.ClassUniversal, ber.TypePrimative, ber.TagInteger, messageID, "MessageID"))
	return packet
}

func createLDAPResponse(tag uint8, resultCode uint64) *ber.Packet {
	packet := ber.Encode(ber.ClassApplication, ber.TypeConstructed, tag, nil, "LDAPResponse")
	packet.AppendChild(ber.NewInteger(ber.ClassUniversal, ber.TypePrimative, ber.TagInteger, resultCode, "resultCode"))
	packet.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, "", "matchedDN"))
	packet.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, "", "errorMessage"))
	return packet
}

func createSimpleResponse(messageID uint64, tag uint8, resultCode uint64) *ber.Packet {
	response := createLDAPMessage(messageID)
	response.AppendChild(createLDAPResponse(tag, resultCode))
	return response
}

func createSearchResultEntry(messageID uint64, attributes map[string]string) *ber.Packet {
	response := createLDAPMessage(messageID)
	entry := ber.Encode(ber.ClassApplication, ber.TypeConstructed, ApplicationSearchResultEntry, nil, "SearchResultEntry")
	entry.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, attributes["cn"], "objectName"))
	attributeSequence := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSequence, nil, "attributes")
	for key, value := range attributes {
		attributeSequence.AppendChild(createAttribute(key, value))
	}
	entry.AppendChild(attributeSequence)
	response.AppendChild(entry)
	return response
}

func createAttribute(name, value string) *ber.Packet {
	attribute := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSequence, nil, "attribute")
	attribute.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, name, "type"))
	values := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSet, nil, "values")
	values.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, value, "value"))
	attribute.AppendChild(values)
	return attribute
}

const (
	ApplicationBindRequest           = 0
	ApplicationBindResponse          = 1
	ApplicationUnbindRequest         = 2
	ApplicationSearchRequest         = 3
	ApplicationSearchResultEntry     = 4
	ApplicationSearchResultDone      = 5
	ApplicationModifyRequest         = 6
	ApplicationModifyResponse        = 7
	ApplicationAddRequest            = 8
	ApplicationAddResponse           = 9
	ApplicationDelRequest            = 10
	ApplicationDelResponse           = 11
	ApplicationModifyDNRequest       = 12
	ApplicationModifyDNResponse      = 13
	ApplicationCompareRequest        = 14
	ApplicationCompareResponse       = 15
	ApplicationAbandonRequest        = 16
	ApplicationSearchResultReference = 19
	ApplicationExtendedRequest       = 23
	ApplicationExtendedResponse      = 24
)

const (
	LDAPResultSuccess                      = 0
	LDAPResultOperationsError              = 1
	LDAPResultProtocolError                = 2
	LDAPResultTimeLimitExceeded            = 3
	LDAPResultSizeLimitExceeded            = 4
	LDAPResultCompareFalse                 = 5
	LDAPResultCompareTrue                  = 6
	LDAPResultAuthMethodNotSupported       = 7
	LDAPResultStrongAuthRequired           = 8
	LDAPResultReferral                     = 10
	LDAPResultAdminLimitExceeded           = 11
	LDAPResultUnavailableCriticalExtension = 12
	LDAPResultConfidentialityRequired      = 13
	LDAPResultSaslBindInProgress           = 14
	LDAPResultNoSuchAttribute              = 16
	LDAPResultUndefinedAttributeType       = 17
	LDAPResultInappropriateMatching        = 18
	LDAPResultConstraintViolation          = 19
	LDAPResultAttributeOrValueExists       = 20
	LDAPResultInvalidAttributeSyntax       = 21
	LDAPResultNoSuchObject                 = 32
	LDAPResultAliasProblem                 = 33
	LDAPResultInvalidDNSyntax              = 34
	LDAPResultAliasDereferencingProblem    = 36
	LDAPResultInappropriateAuthentication  = 48
	LDAPResultInvalidCredentials           = 49
	LDAPResultInsufficientAccessRights     = 50
	LDAPResultBusy                         = 51
	LDAPResultUnavailable                  = 52
	LDAPResultUnwillingToPerform           = 53
	LDAPResultLoopDetect                   = 54
	LDAPResultNamingViolation              = 64
	LDAPResultObjectClassViolation         = 65
	LDAPResultNotAllowedOnNonLeaf          = 66
	LDAPResultNotAllowedOnRDN              = 67
	LDAPResultEntryAlreadyExists           = 68
	LDAPResultObjectClassModsProhibited    = 69
	LDAPResultAffectsMultipleDSAs          = 71
	LDAPResultOther                        = 80

	ErrorNetwork         = 200
	ErrorFilterCompile   = 201
	ErrorFilterDecompile = 202
	ErrorDebugging       = 203
)
