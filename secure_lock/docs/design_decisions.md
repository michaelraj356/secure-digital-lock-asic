\# Design Decisions — Secure Digital Lock System



\## 1. Why I chose these timer values



\- \*\*AUTO\_LOCK\_CYCLES = 16 (sim) / 5,000,000 (hardware)\*\*  

&#x20; In simulation, 16 cycles keeps tests fast. In real hardware at 10 MHz,  

&#x20; 5,000,000 cycles = 500ms — enough for a human to visually see the LED.  

&#x20; I chose 500ms as a balance: short enough to feel responsive, long enough to be visible.



\- \*\*LOCKOUT\_CYCLES = 32 (sim) / 10,000,000 (hardware)\*\*  

&#x20; In hardware, 10,000,000 cycles = 1 second lockout per 3 wrong attempts.  

&#x20; Real systems (ATMs, phones) use 30 seconds to 5 minutes. For a demo  

&#x20; TinyTapeout chip, 1 second is enough to demonstrate the behavior clearly.



\- \*\*Trade-off\*\*: Using `ifdef SIM` means the same RTL works for both fast  

&#x20; simulation and human-visible hardware demo without code duplication.



\---



\## 2. Why I chose this FSM structure



\- \*\*6 states instead of fewer\*\*:  

&#x20; I separated VERIFY from ERROR deliberately. If I combined them, I would  

&#x20; need to handle attempt counting and error signaling in the same state,  

&#x20; making transitions ambiguous. Separate states = separate responsibilities.  

&#x20; IDLE and INPUT are separated so the system has a clear "waiting" state  

&#x20; vs an "actively collecting" state — important for the ena signal behavior.



\- \*\*State transitions on posedge clk\*\*:  

&#x20; All transitions are synchronous (Moore FSM). This avoids glitches on  

&#x20; outputs, which is critical for ASIC — combinational paths to output  

&#x20; pads can cause unwanted pulses that damage external circuits.



\- \*\*VERIFY is a 1-cycle state\*\*:  

&#x20; Verification happens in a single clock cycle. This is fine for 4-digit  

&#x20; comparison — the combinational logic settles well within one clock period  

&#x20; at any reasonable ASIC frequency.



\---



\## 3. Edge cases I considered



\- \*\*Enter button held for many cycles\*\*:  

&#x20; Handled by `enter\_rise = enter \& \~enter\_prev`. Only the FIRST cycle of  

&#x20; a high enter signal triggers storage. A held button = one digit, always.



\- \*\*Input changes while enter is high\*\*:  

&#x20; Since we use the registered `enter\_prev`, the value of `in` is sampled  

&#x20; at the same clock edge as the rising-edge detection. This is the standard  

&#x20; synchronous sampling pattern — input must be stable at the rising clock  

&#x20; edge, same rule as any D flip-flop setup time.



\- \*\*Reset during any state\*\*:  

&#x20; Synchronous reset overrides everything. The FSM returns to IDLE,  

&#x20; attempts clears to 0, all outputs go low. This is deterministic and safe.



\- \*\*Enter pressed during SUCCESS or LOCKOUT\*\*:  

&#x20; No transition is triggered. This is a deliberate security decision:  

&#x20; — In SUCCESS: user cannot abort auto-lock (prevents accidental re-entry)  

&#x20; — In LOCKOUT: user cannot bypass the penalty (security enforcement)



\- \*\*ena=0 (TinyTapeout multiplexer off)\*\*:  

&#x20; All state is frozen. `enter\_prev` still tracks the enter signal to  

&#x20; avoid a false rising edge when ena is re-asserted.



\---



\## 4. What I learned building the testbench



\- \*\*The hardest issue\*\*: Timing of registered outputs. `error\_led` is only  

&#x20; high for exactly 1 clock cycle. Without pulse-latching, the testbench  

&#x20; would check the signal after it had already gone low — always failing.



\- \*\*I used `error\_seen` because\*\*: A register that latches any assertion  

&#x20; of a 1-cycle signal gives reliable detection regardless of when the  

&#x20; check runs. This is how real verification engineers write self-checking  

&#x20; testbenches.



\- \*\*If I built this again\*\*: I would add a timeout watchdog from the start  

&#x20; and use parameterized tasks for repeated patterns. I would also add  

&#x20; assertions (SVA or simple `$assert`) to catch illegal state transitions.



\---



\## 5. ASIC considerations



\- \*\*Area (\~51 flip-flops total)\*\*:

&#x20; - digit\[0:3]: 16 FFs (4 bits × 4 registers)

&#x20; - state: 3 FFs

&#x20; - digit\_idx: 2 FFs

&#x20; - attempts: 2 FFs

&#x20; - timer: 8 FFs (sim) or 24 FFs (hardware)

&#x20; - enter\_prev: 1 FF

&#x20; - unlock\_led, error\_led, lockout\_led: 3 FFs

&#x20; - Plus combinational: 4 comparators (16-bit total) for password\_ok

&#x20; - \*\*Total: \~35 FFs (sim) or \~51 FFs (hardware)\*\*

&#x20; - This is well under 10% of a TinyTapeout tile.



\- \*\*Critical path\*\*:  

&#x20; Probably the `password\_ok` combinational comparison: 4 × 4-bit equality  

&#x20; checks ANDed together. At 10 MHz (100ns period), this is trivially fast.  

&#x20; Even at 100 MHz it would easily meet timing.



\- \*\*Power reduction ideas\*\*:  

&#x20; - Clock gate the digit registers (only toggle when enter\_rise=1)  

&#x20; - Use Gray code for state encoding (reduces switching activity)  

&#x20; - For production: add power-down state when idle for many cycles  

&#x20; These optimizations are unnecessary for a TinyTapeout demo but are good  

&#x20; interview talking points.



\---



\## 6. Why 4 improvements were made (v2.0)



| Fix | Problem Solved |

|-----|----------------|

| IDLE waits for enter | System was instantly entering INPUT state; no real "standby" mode |

| Saturating attempts counter | Counter could overflow at 2-bit max; now clamped at 3 |

| ena signal handling | TT multiplexer signal was ignored; state ran even when design was inactive |

| `ifdef SIM timing | 16-cycle timer is invisible to humans; real hardware needs 500ms+ |

