# Fintech Transaction Ledger & Duplicate Transaction Sentinel

**Project 60** · Object Oriented Programming using Java & Kotlin (4CTGC2011) · B.Tech III Semester
School of Engineering and Technology, CMR University, Bengaluru · 2026–2027

| | |
|---|---|
| **Students** | Sukanya Roy Chowdhury (25BBTCG065), Harini S (25BBTCG019) |
| **Guide** | Dr. Pandava Sudharshan Babu, Associate Professor, Dept. of CE |
| **Department** | Computer Science and Technology (HOD: Dr. K V Prasad) |

A console Java application that simulates a payment ledger which **never debits an account twice for the same payment**, even when a gateway retries a webhook, a mobile app resubmits after a timeout, or an attacker replays a captured request from several threads at once.

---

## The problem

Payment gateways deliver webhooks *at least once*, so the same payment can arrive many times. A naive ledger would debit the customer on every delivery. This project adds a **sentinel** in front of the ledger: every transaction is reduced to a SHA-256 idempotency key, and a key that was already accepted inside the idempotency window is answered with the *original confirmation* instead of a second debit.

Example from the project brief: `TXN-9912`, Rs 2,500 by UPI, is retried 800 ms later. The retry is detected, the cached confirmation is returned, and the balance is debited exactly once.

## Features

- **Duplicate detection** with a SHA-256 hash of transaction id, sender, receiver, amount and payload fingerprint, kept in a `HashSet` with a 60 s window.
- **Tamper detection**: the same transaction id reused with different content is rejected.
- **Generic `Transaction<T extends PaymentPayload>`** carrying UPI, card (Luhn check) or crypto (wallet format) payloads, with runtime polymorphism.
- **Atomic debit and credit** under one lock; overdrafts are rejected and a failed transaction releases its key so a legitimate retry is not blocked.
- **Append-only ledger** where every entry stores the hash of the previous one (tamper-evident chain, `verifyChain()`).
- **Concurrency**: producer threads (`extends Thread`), worker threads (`implements Runnable`), a `PriorityQueue` hand-off using `wait()` / `notifyAll()`, and duplicates that arrive while the original is still in flight wait for its confirmation.
- **Four custom checked exceptions** under a common `LedgerException`.
- **Fraud flagging** of senders whose payloads are replayed repeatedly.

## Architecture

![System architecture](docs/images/fig_architecture.png)

Processing pipeline of one transaction:

![Processing pipeline](docs/images/fig_pipeline.png)

More diagrams are in [`docs/images`](docs/images): payload model, ledger core, exception hierarchy and the concurrency classes (UML).

## Project structure

```
fintech-ledger-sentinel/
├── src/com/fintech/ledger/     26 Java source files (package com.fintech.ledger)
│   ├── FintechLedgerApp.java        entry point, 7 demo scenarios
│   ├── LedgerEngine.java            balances, ledger, submit() pipeline
│   ├── IdempotencyFilter.java       the duplicate sentinel
│   ├── Transaction.java             generic immutable transaction
│   ├── PaymentPayload.java          abstract base of UPI / card / crypto payloads
│   ├── TransactionQueue.java        PriorityQueue + wait/notifyAll
│   ├── TransactionWorker.java       Runnable consumer
│   ├── WebhookReplayProducer.java   Thread-based producer
│   └── ...                          exceptions, Money, HashUtil, LedgerEntry, AuditLog, etc.
├── docs/
│   ├── index.html                   project page (GitHub Pages ready)
│   ├── images/                      architecture, flow and UML diagrams
│   ├── sample-output/console-output.txt
│   └── GIT_COMMIT_PLAN.md           suggested commit sequence
├── build.sh / build.bat             compile
├── run.sh / run.bat                 compile (if needed) and run
├── README.md / README.txt
├── LICENSE
└── .gitignore
```

## Requirements

- JDK 17 or newer (developed and tested on OpenJDK 21)
- No external libraries, no build tool needed

## Build and run

**Linux / macOS**

```bash
./build.sh
./run.sh
```

**Windows**

```bat
build.bat
run.bat
```

**Manually**

```bash
javac -d out src/com/fintech/ledger/*.java
java -cp out com.fintech.ledger.FintechLedgerApp
```

**In an IDE (IntelliJ IDEA / Eclipse):** create a Java project, mark `src` as the source root and run `com.fintech.ledger.FintechLedgerApp`.

## Demo scenarios

`FintechLedgerApp` runs seven scenarios and prints the audit trail:

| # | Scenario | What it shows |
|---|---|---|
| 1 | UPI payment retried after 800 ms (`TXN-9912`) | duplicate suppressed, single debit, tampered replay rejected |
| 2 | Overdraft | `InsufficientFundsException`, failed key released |
| 3 | UPI, card and crypto payloads | generic `Transaction<T>`, hash chain verified |
| 4 | Nine invalid inputs | every validation rule and custom exception |
| 5 | Idempotency window boundary | replay inside the window suppressed, replay after it treated as new |
| 6 | Concurrent replay storm | 3 producers, 4 workers, 136 deliveries of 60 unique payments |
| 7 | Interrupting an idle worker | clean shutdown on `InterruptedException` |

Scenario 6 ends with automatic integrity checks. A real run gives exactly 60 commits and 76 suppressed duplicates, balances equal to a single-threaded calculation, total funds conserved and an intact hash chain. The full output of a run is in [`docs/sample-output/console-output.txt`](docs/sample-output/console-output.txt).

```
Integrity checks
  exactly one commit per unique payment : PASS
  every replay suppressed               : PASS
  balances equal single-thread result   : PASS
  total funds conserved (Rs 10000000.00) : PASS
  ledger hash chain intact              : PASS
```

## OOP concepts used

| Concept | Where |
|---|---|
| Classes, objects, constructors (`this()`, `super()`) | `UPIPaymentPayload`, `Transaction` |
| Inheritance and abstract classes | `PaymentPayload` and its three subclasses |
| Interfaces | `Verifiable`, `Comparable<LedgerEntry>`, `Comparator`, `Runnable` |
| Polymorphism (overriding) | `validate()`, `fingerprint()`, `describe()` |
| Encapsulation and immutability | private final fields in `Transaction`, `Confirmation`, `LedgerEntry` |
| Generics | `Transaction<T extends PaymentPayload>`, `LedgerUtils.max()` |
| Custom exception hierarchy | `LedgerException` and four subclasses |
| Collections | `HashMap`, `HashSet`, `TreeSet`, `TreeMap`, `ArrayList`, `LinkedList`, `PriorityQueue`, `Iterator`, `ListIterator` |
| Strings | `StringBuilder`, `StringBuffer`, `String.format` |
| Multithreading and synchronization | `synchronized`, `wait()`, `notifyAll()`, `AtomicInteger`, thread states, `interrupt()`, `join()` |
| Enums | `Outcome` |

## Design notes and known limitations

- **Money uses `double`**, rounded to paise after each operation, as the project brief specifies. A production ledger should use `BigDecimal` or integer paise.
- **The idempotency window is bounded** (60 s by default). A replay after expiry is treated as a new payment, as scenario 5 demonstrates. A real system would persist keys for longer and use a client-supplied idempotency key.
- **State is in memory.** There is no database, so state is lost on exit.
- **Card numbers are never stored**, only the last four digits and the Luhn result.

## Regenerating the diagrams

The diagrams are generated from `docs/images/generate_diagrams.py` (needs Python 3, Pillow and Graphviz `dot`).

## License

Released under the MIT License, see [LICENSE](LICENSE).
