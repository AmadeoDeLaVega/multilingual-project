import Lake
open Lake DSL

package «TacticParser» where

@[default_target]
lean_lib «TacticParser» where

lean_lib «TacticParser.Example» where

lean_exe «tactic-parser» where
  root := `TacticParser.Main
  supportInterpreter := true

lean_exe «tactic-extractor» where
  root := `TacticParser.TacticExtractorMain
  supportInterpreter := true

lean_exe «dependency-parser» where
  root := `TacticParser.DependencyParserMain
  supportInterpreter := true
