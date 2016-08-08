package main

import (
	"fmt"
	"go/ast"
	"go/token"

	"reflect"
)

type varState int

const (
	Nil varState = iota
	Unused
	Used
)

type varUsage struct {
	state    varState
	position token.Pos
}

func copyVarMap(a map[string]varUsage) map[string]varUsage {
	b := make(map[string]varUsage)
	for k, v := range a {
		b[k] = v
	}
	return b
}

func checkNoAssignUnusedBody(info fileMetadata, body []ast.Stmt, declared map[string]varUsage) {
	for _, st := range body {
		noAssignStatement(info, st, declared)
	}
}

func assignUsedForExpr(info fileMetadata, expr ast.Expr, scope map[string]varUsage) {
	if expr == nil {
		return
	}
	switch v := expr.(type) {
	case *ast.Ident:
		if vinfo, ok := scope[v.Name]; ok {
			if vinfo.state != Used {
				scope[v.Name] = varUsage{Used, vinfo.position}
			}
		} else {
			scope[v.Name] = varUsage{Used, 0}
		}
	case *ast.StarExpr:
		assignUsedForExpr(info, v.X, scope)
	case *ast.BinaryExpr:
		assignUsedForExpr(info, v.X, scope)
		assignUsedForExpr(info, v.Y, scope)
	case *ast.CallExpr:
		assignUsedForExpr(info, v.Fun, scope)
		for _, arg := range v.Args {
			assignUsedForExpr(info, arg, scope)
		}
	case *ast.CompositeLit:
		assignUsedForExpr(info, v.Type, scope)
		for _, e := range v.Elts {
			assignUsedForExpr(info, e, scope)
		}
	case *ast.IndexExpr:
		assignUsedForExpr(info, v.X, scope)
		assignUsedForExpr(info, v.Index, scope)
	case *ast.KeyValueExpr:
		//Only the value counts
		assignUsedForExpr(info, v.Value, scope)
	case *ast.ParenExpr:
		assignUsedForExpr(info, v.X, scope)
	case *ast.SelectorExpr:
		// The selected field doesn't count
		assignUsedForExpr(info, v.X, scope)
	case *ast.SliceExpr:
		assignUsedForExpr(info, v.X, scope)
		assignUsedForExpr(info, v.Low, scope)
		assignUsedForExpr(info, v.High, scope)
		assignUsedForExpr(info, v.Max, scope)
	case *ast.UnaryExpr:
		assignUsedForExpr(info, v.X, scope)
	case *ast.TypeAssertExpr:
		assignUsedForExpr(info, v.X, scope)
	default:
	}
}

func lhsForExpr(info fileMetadata, exp ast.Expr, tok token.Token, scope map[string]varUsage) {
	if exp == nil {
		return
	}
	var name string
	var pos token.Pos
	switch expv := exp.(type) {
	case *ast.Ident:
		name = expv.Name
		pos = expv.Pos()
	case *ast.StarExpr:
		switch x := expv.X.(type) {
		case *ast.SelectorExpr:
			name = x.Sel.String()
			pos = expv.Pos()
		case *ast.Ident:
			name = x.Name
			pos = expv.Pos()
		default:
			cpos := info.fset.Position(expv.Pos())
			fmt.Printf("%s:Weird type of StarExpr: %s\n", cpos, reflect.TypeOf(expv.X))
			return
		}
	case *ast.IndexExpr:
		assignUsedForExpr(info, expv.X, scope)
		assignUsedForExpr(info, expv.Index, scope)
		return
	case *ast.SelectorExpr:
		assignUsedForExpr(info, expv.X, scope)
		return
	default:
		fmt.Println("noAssignStatement: weird assign type", reflect.TypeOf(exp))
		return
	}
	vinfo, ok := scope[name]
	if ok {
		if tok == token.ASSIGN && vinfo.state == Unused {
			vpos := info.fset.Position(vinfo.position)
			cpos := info.fset.Position(pos)
			fmt.Printf("%s:Declared variable `%s` which goes unused\n", vpos, name)
			fmt.Printf("%s:`%s` gets covered here\n", cpos, name)
			hasErrors = true
		}
		if tok == token.ASSIGN && vinfo.state == Nil {
			scope[name] = varUsage{Unused, vinfo.position}
		}
	} else {
		if tok == token.DEFINE || tok == token.ASSIGN {
			if name != "_" && name != "err" {
				scope[name] = varUsage{Unused, pos}
			}
		}
	}
}

func noAssignStatement(info fileMetadata, st ast.Stmt, localScope map[string]varUsage) {
	if st == nil {
		return
	}

	switch v := st.(type) {
	// Things which we're checking
	case *ast.AssignStmt:
		for _, rhs := range v.Rhs {
			assignUsedForExpr(info, rhs, localScope)
		}
		for _, exp := range v.Lhs {
			lhsForExpr(info, exp, v.Tok, localScope)
		}
	case *ast.DeclStmt:
		decl := v.Decl.(*ast.GenDecl)
		if decl.Tok == token.VAR {
			for _, spec := range decl.Specs {
				s := spec.(*ast.ValueSpec)
				if typ, ok := s.Type.(*ast.Ident); ok {
					if typ.Name == "error" {
						continue
					}
				}
				for _, varname := range s.Names {
					if _, ok := localScope[varname.Name]; !ok {
						if varname.Name != "_" {
							localScope[varname.Name] = varUsage{Nil, varname.Pos()}
						}
					}
				}
			}
		}
		// Things which may recurse
	case *ast.BlockStmt:
		checkNoAssignUnusedBody(info, v.List, localScope)
	case *ast.DeferStmt:
		//TODO(barakmich): Check this
		if *debug {
			fmt.Println("TODO: Check a defer statement")
		}
	case *ast.GoStmt:
		assignUsedForExpr(info, v.Call, localScope)
	case *ast.ForStmt:
		noAssignStatement(info, v.Init, localScope)
		assignUsedForExpr(info, v.Cond, localScope)
		noAssignStatement(info, v.Post, localScope)
		checkNoAssignUnusedBody(info, v.Body.List, localScope)
	case *ast.IfStmt:
		ifScope := make(map[string]varUsage)
		elseScope := make(map[string]varUsage)
		noAssignStatement(info, v.Init, localScope)
		assignUsedForExpr(info, v.Cond, localScope)
		checkNoAssignUnusedBody(info, v.Body.List, ifScope)
		noAssignStatement(info, v.Else, elseScope)
		for k, varinfo := range ifScope {
			if varinfo.state == Used {
				localScope[k] = varinfo
			}
		}
		for k, varinfo := range elseScope {
			if varinfo.state == Used {
				localScope[k] = varinfo
			}
		}
	case *ast.RangeStmt:
		if v.Tok == token.ILLEGAL {
			pos := info.fset.Position(v.Pos())
			fmt.Printf("%s:Illegal range\n", pos)
		}
		assignUsedForExpr(info, v.X, localScope)
		lhsForExpr(info, v.Key, v.Tok, localScope)
		lhsForExpr(info, v.Value, v.Tok, localScope)
		checkNoAssignUnusedBody(info, v.Body.List, localScope)
	case *ast.SelectStmt:
		checkNoAssignUnusedBody(info, v.Body.List, localScope)
	case *ast.SwitchStmt:
		noAssignStatement(info, v.Init, localScope)
		checkNoAssignUnusedBody(info, v.Body.List, localScope)
	case *ast.TypeSwitchStmt:
		noAssignStatement(info, v.Init, localScope)
		noAssignStatement(info, v.Assign, localScope)
		checkNoAssignUnusedBody(info, v.Body.List, localScope)
	case *ast.CaseClause:
		newScope := make(map[string]varUsage)
		for _, expr := range v.List {
			assignUsedForExpr(info, expr, localScope)
		}
		checkNoAssignUnusedBody(info, v.Body, newScope)
		for k, varinfo := range newScope {
			if varinfo.state == Used {
				localScope[k] = varinfo
			}
		}
	case *ast.CommClause:
		newScope := make(map[string]varUsage)
		noAssignStatement(info, v.Comm, localScope)
		checkNoAssignUnusedBody(info, v.Body, newScope)
		for k, varinfo := range newScope {
			if varinfo.state == Used {
				localScope[k] = varinfo
			}
		}
		// Things which are easy
	case *ast.IncDecStmt:
		// IncDec shouldn't count as usage...
	case *ast.ReturnStmt:
		for _, res := range v.Results {
			assignUsedForExpr(info, res, localScope)
		}
	case *ast.SendStmt:
		assignUsedForExpr(info, v.Chan, localScope)
		assignUsedForExpr(info, v.Value, localScope)
	case *ast.ExprStmt:
		assignUsedForExpr(info, v.X, localScope)
	case *ast.LabeledStmt:
		noAssignStatement(info, v.Stmt, localScope)
	case *ast.BranchStmt:
	case *ast.EmptyStmt:
	case *ast.BadStmt:
		pos := info.fset.Position(v.Pos())
		if *debug {
			fmt.Printf("%s:Bad statement?\n", pos)
		}
	default:
		pos := info.fset.Position(v.Pos())
		if *debug {
			fmt.Println("The hell is", reflect.TypeOf(st), pos)
		}
	}
}

func CheckNoAssignUnused(info fileMetadata) {
	for _, obj := range info.f.Scope.Objects {
		funcScope := make(map[string]varUsage)
		if obj.Kind == ast.Fun {
			decl := obj.Decl.(*ast.FuncDecl)
			for _, r := range decl.Type.Params.List {
				for _, n := range r.Names {
					funcScope[n.Name] = varUsage{Unused, n.Pos()}
				}
			}
			checkNoAssignUnusedBody(info, decl.Body.List, funcScope)
			if *debug {
				for k, v := range funcScope {
					if v.state != Used {
						pos := info.fset.Position(v.position)
						fmt.Printf("%s:DEBUG: `%s` apparently Unused?\n", pos, k)
					}
				}
			}

		}
	}
}
