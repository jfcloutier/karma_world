# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.LargeNumbers, only_greater_than: 86400},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, parens: true},
        {Credo.Check.Readability.FunctionNames, false},
        {Credo.Check.Readability.StrictModuleLayout, tags: []},
        {Credo.Check.Readability.Specs, tags: []},

        ### Below are checks we will want to enable at a later date ###
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Refactor.Nesting, max_nesting: 4},

        ### These ones are more serious warnings ###
        {Credo.Check.Warning.UnsafeExec, false},
        {Credo.Check.Warning.ApplicationConfigInModuleAttribute, false}
      ]
    }
  ]
}
