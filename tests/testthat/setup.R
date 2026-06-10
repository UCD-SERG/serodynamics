# Escalate lifecycle deprecation signals to errors during testing.
#
# Many tidyverse deprecations (e.g. using the `.data` pronoun in a
# tidy-selection context such as `select()` or `.by =`) are *soft*
# deprecations: `lifecycle::deprecate_soft()` only signals when called
# from the global environment or the package under development, so they
# stay silent inside an installed-package test run -- and `options(warn =
# 2)` never catches them because the signal is suppressed before it
# becomes a warning. Setting `lifecycle_verbosity = "error"` overrides
# that suppression and turns every lifecycle deprecation into a hard
# error, so non-idiomatic / soon-to-be-removed calls fail CI here rather
# than surfacing later as a broken build against a newer dependency.
options(lifecycle_verbosity = "error") # nolint: undesirable_function_linter.
