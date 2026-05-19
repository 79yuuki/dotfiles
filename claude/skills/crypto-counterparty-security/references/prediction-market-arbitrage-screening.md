# Prediction Market Arbitrage Screening Checklist

Use this before treating cross-platform prediction-market spreads as live-trading candidates. This is a risk/readiness checklist, not a proof that a strategy is profitable.

## First conclusion line

Start every report with one of:

- `Profitability: proven` — reproducible filled trades after all costs.
- `Profitability: plausible` — visible spread survives conservative fees/slippage, but not yet filled.
- `Profitability: unknown` — spread exists in UI/data, but liquidity, settlement, or mapping is unresolved.
- `Profitability: weak` — spread disappears after costs or size limits.

## Screening steps

1. **Market mapping**
   - Same event, same resolution source, same deadline, same cancellation/void rules.
   - Note wording differences that can break equivalence.
2. **Outcome polarity**
   - Confirm whether the hedge is YES/NO, inverse outcomes, or mutually exclusive buckets.
   - Write the payoff table before calculating edge.
3. **Executable liquidity**
   - Minimum depth at target price on both venues.
   - Quote age and whether the book refills after a small fill.
   - Reject `$0`/dust-liquidity examples unless the research goal is mapping only.
4. **All-in cost model**
   - Trading fees, spread, slippage, funding/opportunity cost, withdrawal fees, gas, FX/stablecoin conversion, and expected time locked.
5. **Settlement and counterparty mismatch**
   - Venue terms, KYC/withdrawal limits, dispute windows, oracle/source risk, region restrictions.
6. **Capital and tail risk**
   - Max capital tied up, worst-case loss if one leg fails or gets voided, operational failure modes.
7. **Paper-trade validation**
   - Record bid/ask snapshots, attempted size, simulated fills, and post-fee PnL.
   - Require repeated examples before `$100-$200` live tests.

## Go / no-go

- Go to paper trading only if mapping is exact, costs are modeled, liquidity is executable, and the edge remains after conservative slippage.
- Block live trading if profitability is only UI-visible, if settlement rules differ, or if one leg cannot be exited/withdrawn reliably.
