===1.2.1
- Introduced `Waterfall.with_reversible_flow`, makes `reverse_flow` optionnal, may save memory
- outflow is now lazy loaded

===1.2.0
- Removed `undam`.
- Introduced `reverse_flow`

===1.1.0
- Removed `chain_wf`.
- Introduced `halt_chain`

===1.0.6
Alias Wf with Flow

=== 1.0.5
- naming: changed flowing to has_flown to clarify its not related to damming
- spec change

=== 1.0.4
- add clearer error messages
- deprecate chain_wf
- prevent from damming falsy values

=== 1.0.3
- Small refactors
- if waterfall 1 calls waterfall 2 and waterfall2 is dammed, now waterfall1 is able to get values from waterfall2's outflow

=== 1.0.2
Initial release
