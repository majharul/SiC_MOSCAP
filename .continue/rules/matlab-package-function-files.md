---
globs: "**/*.m"
description: Apply when working with MATLAB package (+folder) organization and
  calling functions across package boundaries.
alwaysApply: false
---

In MATLAB `+package` folders, a plain function file (e.g. `+pkg/helpers.m`) can only export ONE public function — the one matching the filename. All other functions in that file are local/private and invisible outside. To expose multiple functions via `pkg.helpers.funcA(...)` syntax, the file MUST be a `classdef` with `methods (Static)`. Never use `pkg.file.localFunc()` syntax with plain function files.