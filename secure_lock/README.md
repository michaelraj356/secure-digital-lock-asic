\# 🔐 Secure Digital Lock System — TinyTapeout (ASIC Design)



\## 📌 Overview



This project implements a \*\*4-digit password-protected digital lock\*\* using a \*\*finite state machine (FSM)\*\*, designed for \*\*ASIC implementation on TinyTapeout (Sky130 process)\*\*.



The system accepts sequential digit inputs and verifies them against a predefined password. It includes robust features such as \*\*auto-lock\*\*, \*\*attempt limiting\*\*, and \*\*lockout protection\*\* after multiple failures.



\---



\## ⚙️ Key Features



\*  FSM-based control logic (6 states)

\*  Rising-edge detection for input stability

\*  Auto-lock after successful unlock

\*  Lockout after 3 incorrect attempts

\*  Glitch-free registered outputs

\*  Simulation vs hardware timing support (`ifdef SIM`)

\*  TinyTapeout-compatible wrapper (`tt\_um\_secure\_lock`)

\*  Low resource usage (\~35 flip-flops)



\---



\## 🧠 FSM Architecture



```

IDLE → INPUT → VERIFY → SUCCESS → IDLE

&#x20;                    ↓

&#x20;                  ERROR → (attempts++)

&#x20;                    ↓

&#x20;           attempts < 3 → IDLE

&#x20;           attempts = 3 → LOCKOUT → IDLE

```



\---



\## 🔢 Default Password



```

1 → 2 → 3 → 4

```



To modify the password, update:



```

PASS0, PASS1, PASS2, PASS3

```



inside the `secure\_lock` module.



\---



\## 🔌 Pin Configuration



\### Inputs (`ui\_in`)



| Pin          | Signal  | Description                        |

| ------------ | ------- | ---------------------------------- |

| `ui\_in\[3:0]` | `digit` | Input digit (0–9)                  |

| `ui\_in\[4]`   | `enter` | Rising edge triggers input capture |



\### Outputs (`uo\_out`)



| Pin         | Signal        | Description            |

| ----------- | ------------- | ---------------------- |

| `uo\_out\[0]` | `unlock\_led`  | HIGH when unlocked     |

| `uo\_out\[1]` | `error\_led`   | HIGH on wrong password |

| `uo\_out\[2]` | `lockout\_led` | HIGH during lockout    |



\---



\## 🛠️ How It Works



1\. Apply reset (`rst\_n = 0 → 1`)

2\. Provide digit input via `ui\_in\[3:0]`

3\. Pulse `enter` (`ui\_in\[4]`)

4\. Repeat for 4 digits

5\. System verifies password:



&#x20;  \* Correct → Unlock

&#x20;  \* Wrong → Error / Lockout



\---



\## 📁 Project Structure



```

secure\_lock/

&#x20;├── src/

&#x20;│    └── secure\_lock.v          # RTL + TinyTapeout wrapper

&#x20;│

&#x20;├── sim/

&#x20;│    └── tb\_secure\_lock.v       # Testbench (16 test cases)

&#x20;│

&#x20;├── docs/

&#x20;│    ├── waveform.png           # Simulation waveform

&#x20;│    ├── test\_results.png       # Verification output

&#x20;│

&#x20;└── README.md

```



\---



\## 📈 Waveform Verification



The waveform demonstrates:



\* Correct password entry sequence

\* Unlock activation

\* Error detection

\* Lockout behavior after 3 failures



!\[Waveform](docs/waveform.png)



\---



\## 🧪 Functional Verification



The design was tested using a comprehensive testbench covering:



\* ✔ Correct password

\* ✔ Wrong attempts tracking

\* ✔ Lockout after 3 failures

\* ✔ Recovery after timeout

\* ✔ Reset behavior



\*\*Result:\*\*



```

RESULT: 16 PASS, 0 FAIL

ALL TESTS PASSED

```



!\[Test Results](docs/test\_results.png)



\---



\## ⏱️ Timing Configuration



| Mode       | Auto-lock | Lockout   |

| ---------- | --------- | --------- |

| Simulation | 16 cycles | 32 cycles |

| Hardware   | \~500 ms   | \~1 second |



Controlled using:



```verilog

`ifdef SIM

```



\---



\## 🔬 Design Considerations



\* \*\*Edge detection\*\* prevents multiple triggers on held button

\* \*\*Saturating counter\*\* avoids overflow in attempt tracking

\* \*\*State-based outputs\*\* ensure glitch-free behavior

\* \*\*Enable gating (`ena`)\*\* supports TinyTapeout multiplexing

\* \*\*Minimal area usage\*\* for ASIC efficiency



\---



\## 🚀 Tools Used



\* \*\*EDA Playground\*\* — initial verification

\* \*\*Icarus Verilog (v12.0)\*\* — simulation

\* \*\*Vivado (2025.2)\*\* — waveform analysis

\* \*\*TinyTapeout Flow\*\* — ASIC targeting



\---



\## 🎯 Applications



\* Digital access control systems

\* Embedded security modules

\* FPGA/ASIC learning projects

\* Hardware authentication systems



\---



\## 👨‍💻 Author



Michael Raj

ECE Student | VLSI Enthusiast



\---



\## 📌 Status



✔ Fully Verified

✔ Simulation Passed

✔ ASIC Ready (TinyTapeout Compatible)



\---



