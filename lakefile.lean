/-
Copyright (c) 2022 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/
import Lake
open Lake DSL System

package alloy

--------------------------------------------------------------------------------
-- # Alloy Build
--------------------------------------------------------------------------------

lean_lib Alloy

@[default_target]
lean_exe alloy {
  root := `Main
  supportInterpreter := true
}

--------------------------------------------------------------------------------
-- # Module Facets
--------------------------------------------------------------------------------

module_facet alloy.c mod : FilePath := do
  let some alloy ← findLeanExe? `alloy
    | error "no alloy executable configuration found in workspace"
  let exeJob ← alloy.exe.fetch
  let modJob ← mod.leanBin.fetch
  let cFile := mod.irPath "alloy.c"
  exeJob.bindAsync fun exeFile exeTrace => do
  modJob.bindSync fun _ modTrace => do
    let depTrace := exeTrace.mix modTrace
    let trace ← buildFileUnlessUpToDate cFile depTrace do
      logInfo s!"Generating {mod.name} alloy"
      proc {
        cmd := exeFile.toString
        args := #[mod.name.toString, cFile.toString]
        env := #[("LEAN_PATH", (← getLeanPath).toString)]
      }
    return (cFile, trace)

module_facet alloy.c.o mod : FilePath := do
  let oFile := mod.irPath "alloy.c.o"
  let cJob ← fetch <| mod.facet `alloy.c
  let args := #["-I", (← getLeanIncludeDir).toString] ++ mod.leancArgs
  buildFileAfterDep oFile cJob fun cFile => do
    compileO s!"{mod.name} alloy" oFile cFile args "cc"
