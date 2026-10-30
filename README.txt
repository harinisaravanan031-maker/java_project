FINTECH TRANSACTION LEDGER & DUPLICATE TRANSACTION SENTINEL
===========================================================
Project 60 | Object Oriented Programming using Java & Kotlin (4CTGC2011)
B.Tech III Semester, School of Engineering and Technology, CMR University
Academic year 2026-2027

Students : Sukanya Roy Chowdhury (25BBTCG065)
           Harini S (25BBTCG019)
Guide    : Dr. Pandava Sudharshan Babu, Associate Professor, Dept. of CE
Dept.    : Computer Science and Technology (HOD: Dr. K V Prasad)


ABOUT
-----
A console Java application that simulates a payment ledger which never
debits an account twice for the same payment, even when a gateway retries a
webhook or a request is replayed from several threads at once.

Every transaction is reduced to a SHA-256 idempotency key. A key that was
already accepted inside the idempotency window (60 s by default) is answered
with the original confirmation instead of a second debit.

Example: TXN-9912, Rs 2,500 by UPI, is retried 800 ms later. The retry is
detected, the cached confirmation is returned and the balance is debited once.


FEATURES
--------
 * Duplicate detection with SHA-256 keys held in a HashSet
 * Tamper detection (same transaction id, different content)
 * Generic Transaction<T extends PaymentPayload> for UPI, card and crypto
 * Atomic debit + credit, overdraft protection
 * Append-only ledger with a SHA-256 hash chain
 * Producer threads, worker threads, PriorityQueue with wait()/notifyAll()
 * Four custom checked exceptions under LedgerException
 * Fraud flagging of senders with repeated replays


REQUIREMENTS
------------
 * JDK 17 or newer (developed and tested on OpenJDK 21)
 * No external libraries, no build tool


HOW TO BUILD AND RUN
--------------------
Linux / macOS:
    ./build.sh
    ./run.sh

Windows:
    build.bat
    run.bat

Manually:
    javac -d out src/com/fintech/ledger/*.java
    java -cp out com.fintech.ledger.FintechLedgerApp

IDE (IntelliJ IDEA / Eclipse): create a Java project, mark "src" as the source
root and run com.fintech.ledger.FintechLedgerApp.


FOLDER STRUCTURE
----------------
 src/com/fintech/ledger/   26 Java source files
 docs/index.html           project page (GitHub Pages ready)
 docs/images/              architecture, flow and UML diagrams
 docs/sample-output/       console output of a real run
 docs/GIT_COMMIT_PLAN.md   suggested commit sequence
 build.sh, build.bat       compile
 run.sh, run.bat           compile (if needed) and run


DEMO SCENARIOS (printed by FintechLedgerApp)
--------------------------------------------
 1. UPI payment retried after 800 ms (TXN-9912)
 2. Overdraft protection
 3. UPI, card and crypto payloads in one generic Transaction<T>
 4. Nine invalid inputs and their custom exceptions
 5. Idempotency window boundary
 6. Concurrent replay storm: 3 producers, 4 workers, 136 deliveries of 60
    unique payments (exactly 60 commits, 76 duplicates suppressed)
 7. Interrupting an idle worker thread

Scenario 6 finishes with automatic integrity checks (one commit per payment,
all replays suppressed, balances correct, funds conserved, hash chain intact).


KNOWN LIMITATIONS
-----------------
 * Money is stored as double (rounded to paise), as the project brief requires.
   Production code should use BigDecimal or integer paise.
 * The idempotency window is bounded; a replay after it expires is treated as
   a new payment.
 * All state is in memory; nothing is persisted.


LICENSE
-------
MIT License, see the LICENSE file.
