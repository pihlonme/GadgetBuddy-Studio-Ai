# GadgetBuddy Test Lab — Group Status

**Status policy:** A group is `ACTIVE` only when it has an executable artifact and the complete local suite is green. Failures are not hidden or softened: they are isolated, reproduced, converted into a regression case, fixed at the root, and retained as learned protection.

| Group | Mission | Executable artifact | Health | Escalation / learning loop |
| --- | --- | --- | --- | --- |
| Contract Guard | Protect stable domain and serialization contracts | `ContractGuardTests.swift` | ACTIVE | Contract drift blocks the pipeline; document intentional changes and add a regression assertion. |
| Challenger | Reject invalid or undeclared states | `ChallengerTests.swift` | ACTIVE | Reproduce the invalid state, strengthen the invariant, retain the failing case. |
| Red Team | Challenge assumptions with adversarial input | `RedTeamTests.swift` + `adversarial-prompts.json` | ACTIVE | Treat surprising behavior as discovery; reduce to a deterministic scenario and learn from it. |
| Regression Guard | Preserve previously correct behavior | `RegressionTests.swift` + `regression-prompts.json` | ACTIVE | Any regression is isolated before merge; fixed cases become permanent fixtures. |
| Integration Tester | Verify end-to-end sandbox semantics | `SandboxIntegrationTests.swift` | ACTIVE | Trace the failing stage, correct the smallest responsible boundary, rerun the whole chain. |
| Fuzz / Chaos Tester | Exercise deterministic edge conditions | `ChaosTests.swift` | ACTIVE | Crashes or invented facts become named regression cases; randomness is not used in v0.1. |

## Execution profiles

| Profile | Purpose | CI check |
| --- | --- | --- |
| FAST | Contract, Challenger, integration smoke, normal/regression fixtures | `test-lab-fast` |
| CHALLENGE | FAST plus Red Team and deterministic chaos | `test-lab-challenge` |
| FULL LAB | Complete Foundation + Test Lab suite | `test-lab-full` |

## Working culture

- **Green means earned confidence, not complacency.** Passing tests free the team to move faster because the contract is observable.
- **Red means information.** A failure is a precise invitation to improve the system, not a reason to conceal or bypass the check.
- **Every solved issue should leave the system stronger.** If a bug can recur, the learning is incomplete until a regression case captures it.
- **No group is ceremonial.** Every group above maps to code that executes and can stop a faulty change.
