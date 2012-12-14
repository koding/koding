package main

import (
	"fmt"
	"github.com/hsoj/asn1-ber"
	"io"
	"koding/virt"
	"net"
	"strconv"
)

func main() {
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
			response := createLDAPMessage(messageID)
			response.AppendChild(createLDAPResponse(ApplicationBindResponse, LDAPResultSuccess))
			conn.Write(response.Bytes())

		case ApplicationUnbindRequest:
			// ignored

		case ApplicationSearchRequest:
			if !lookupUser(request.Children[6], messageID, conn) {
				// ber.PrintPacket(packet)
			}

			response := createLDAPMessage(messageID)
			response.AppendChild(createLDAPResponse(ApplicationSearchResultDone, LDAPResultSuccess))
			conn.Write(response.Bytes())

		default:
			panic("Unsupported LDAP command")
		}
	}
}

func lookupUser(filter *ber.Packet, messageID uint64, conn net.Conn) bool {
	var attributes map[string]string
	switch findAttributeInFilter(filter, "objectClass") {
	case "posixAccount":
		var vm *virt.VM
		var err error
		if name := findAttributeInFilter(filter, "uid"); name != "" {
			vm, err = virt.FindByName(name)
			if err != nil {
				return true
			}
		} else if uidStr := findAttributeInFilter(filter, "uidNumber"); uidStr != "" {
			uid, _ := strconv.Atoi(uidStr)
			vm, err = virt.FindById(uid >> 8)
			if err != nil {
				return true
			}
		} else {
			return false
		}

		attributes = map[string]string{
			"uid":           vm.Name,
			"userPassword":  "",
			"uidNumber":     strconv.Itoa(vm.Id << 8),
			"gidNumber":     strconv.Itoa(vm.Id << 8),
			"cn":            vm.Name,
			"homeDirectory": "/home/" + vm.Name,
			"loginShell":    "/bin/bash",
			"gecos":         "",
			"description":   "",
		}

	case "posixGroup":
		if findAttributeInFilter(filter, "memberUid") != "" {
			// ignoring group membership queries
			return true
		}

		gidStr := findAttributeInFilter(filter, "gidNumber")
		if gidStr == "" {
			return false
		}
		gid, _ := strconv.Atoi(gidStr)
		vm, err := virt.FindById(gid >> 8)
		if err != nil {
			return true
		}

		attributes = map[string]string{
			"cn":           vm.Name,
			"userPassword": "",
			"memberUid":    "",
			"uniqueMember": "",
			"gidNumber":    gidStr,
		}
	default:
		return false
	}

	response := createLDAPMessage(messageID)
	entry := ber.Encode(ber.ClassApplication, ber.TypeConstructed, ApplicationSearchResultEntry, nil, "SearchResultEntry")
	entry.AppendChild(ber.NewString(ber.ClassUniversal, ber.TypePrimative, ber.TagOctetString, "noName", "objectName"))
	attributeSequence := ber.Encode(ber.ClassUniversal, ber.TypeConstructed, ber.TagSequence, nil, "attributes")
	for key, value := range attributes {
		attributeSequence.AppendChild(createAttribute(key, value))
	}
	entry.AppendChild(attributeSequence)
	response.AppendChild(entry)
	conn.Write(response.Bytes())

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
