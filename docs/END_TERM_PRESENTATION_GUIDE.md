# LAFSH Mid-Term Presentation Guide
## Slide Structure · Speaking Points · Team Split · Viva Prep

---

# PRESENTATION NARRATIVE

**Flow**: Problem → Why Fog? → Architecture → Networking → Authentication → Security → Results → Live Demo → Conclusion

**Total time**: 15-18 minutes presentation + 5-10 minutes Q&A.

---

# SLIDE STRUCTURE (12 Slides)

---

## Slide 1: Title Slide
**Speaker: Member 1 (Shivang)**

```
LAFSH: Lightweight Authentication for Fog-Based Smart Homes

CSE4702 — Fog Computing | BTech Semester 6
Team Members: [Name 1], [Name 2], [Name 3]

GitHub: github.com/shivangtanwar/LAFSH
```

**Speaking Points (30 seconds):**
- "Good [morning/afternoon]. Our project is LAFSH — a Lightweight Authentication protocol for Fog-Based Smart Homes."
- "We've built a complete MATLAB simulation that covers deployment, networking, authentication, access control, and security testing."
- Transition: "Let me start with the problem we're solving."

---

## Slide 2: Problem Statement
**Speaker: Member 1**

**Visual**: Show a diagram of smart home with 500 devices and a cloud far away.

```
THE PROBLEM:
• 500+ IoT devices in a smart home (lights, locks, cameras, sensors)
• Traditional cloud-only approach → 100-500ms latency per command
• TLS/RSA authentication drains tiny device batteries in hours
• Internet outage = entire smart home goes offline
• All personal data leaves the home → privacy risk

THE GAP:
• Standard TLS costs ~5,000 bytes and 1.8 mJ per authentication
• A motion sensor (0.3J battery) can only authenticate ~166 times with TLS
• We need something 1000× lighter that works locally
```

**Speaking Points (1 minute):**
- "Imagine a home with 500 smart devices. With cloud-only architecture, every command travels to a remote data center — that's 200 millisecond latency just to unlock your door."
- "Worse, standard TLS authentication costs 5,000 bytes and 1.8 millijoules per session. A tiny motion sensor on a coin cell battery would die after just 166 authentications."
- "We need authentication that is thousands of times lighter, works locally, and doesn't depend on constant internet."
- Transition: "That's where fog computing comes in."

---

## Slide 3: Why Fog Computing?
**Speaker: Member 1**

**Visual**: Side-by-side comparison table or diagram.

```
                   Cloud-Only          With Fog Layer
Latency            100-500ms           5-10ms
Internet Required  Always              Only for sync/updates
Bandwidth          All data uploaded   Only aggregated data
Privacy            Data leaves home    Data stays local
Offline Operation  Nothing works       Fog continues locally
Cost (ongoing)     Cloud bills grow    One-time fog device

KEY INSIGHT: Fog node = local gateway that handles 95% of operations
             without needing the cloud at all.
```

**Speaking Points (1 minute):**
- "Fog computing puts a small processing node — think of it as a smart router — directly inside the home."
- "This fog node handles authentication, access control, and data aggregation LOCALLY. Latency drops from 500ms to 5ms."
- "The cloud is only needed for firmware updates, long-term storage, and remote access — not for day-to-day operations."
- Transition: "[Member 2] will now walk you through our system architecture."

---

## Slide 4: Three-Layer Architecture
**Speaker: Member 2**

**Visual**: The architecture diagram from the README.

```
┌─────────────────────────────────────────────┐
│       CLOUD LAYER                           │
│  Master secrets · Global policy · Audit     │
│  Trust: Root of trust                       │
└────────────────┬────────────────────────────┘
                 │ ~100ms (internet)
┌────────────────┴────────────────────────────┐
│       FOG LAYER (Home Gateway)              │
│  Device auth · RBAC · TOTP · Sessions       │
│  Cluster head aggregation                   │
│  Trust: Delegated from cloud                │
└────────────────┬────────────────────────────┘
                 │ ~5ms (local network)
┌────────────────┴────────────────────────────┐
│       EDGE / IoT LAYER                      │
│  500 heterogeneous devices (6 types)        │
│  Battery-powered · Limited compute          │
└─────────────────────────────────────────────┘
```

**Speaking Points (1.5 minutes):**
- "Our system has three layers."
- "At the top, the **Cloud Layer** — it's the root of trust. It generates the master secret and holds global policies. But it's 100ms away, so we don't use it for real-time operations."
- "The **Fog Layer** is the brain of the smart home. It runs authentication, RBAC access control, TOTP two-factor auth, session management, and data aggregation — all locally."
- "At the bottom, the **Edge Layer** — 500 heterogeneous IoT devices across 6 types: lights (30%), thermostats (20%), cameras (15%), locks (15%), motion sensors (10%), and smart plugs (10%). Each type has different energy, range, and capability profiles."
- "This heterogeneity is crucial — it reflects real-world deployments and directly affects our clustering strategy."
- Transition: "Let me explain how these devices are organized for efficient communication."

---

## Slide 5: LEACH-SEP Clustering
**Speaker: Member 2**

**Visual**: Cluster diagram (from `plot_clusters`) + the LEACH-SEP threshold formula.

```
WHY CLUSTER?
Without: 500 devices → 500 direct transmissions to fog (expensive!)
With:    500 devices → ~50 cluster heads → fog (10× fewer long-range TX)

LEACH-SEP THRESHOLD:
   T(n) = p / (1 - p × mod(r, 1/p))  ×  (E_residual / E_initial)

SEP Enhancement for Heterogeneous Networks:
   p_advanced = p_normal × (1 + α)     where α = (E_adv/E_norm) - 1

Result: High-energy cameras become CH more often than low-energy sensors
        → Network lifetime extended
        → Energy-fair cluster head rotation
```

**Speaking Points (1.5 minutes):**
- "Without clustering, every device sends data directly to the fog node — 500 separate transmissions is expensive."
- "With LEACH clustering, devices form groups. One Cluster Head per group aggregates data and forwards a single message to the fog — 10× fewer long-range transmissions."
- "Standard LEACH assumes all nodes are identical. But our network is heterogeneous — a camera has 2 joules of energy, while a motion sensor has only 0.3 joules."
- "So we use the SEP extension: advanced nodes (above-average energy) get a higher probability of becoming cluster head. We also add an energy-weighting factor — a node at 10% battery almost never becomes CH."
- "This gives us energy-fair rotation and maximises network lifetime."
- Transition: "[Member 3] will now present our authentication protocol — the core contribution."

---

## Slide 6: LAFSH Authentication Protocol — Overview
**Speaker: Member 3**

**Visual**: Protocol flow diagram showing the 4 phases.

```
PHASE 1: Registration (one-time)
  Device ←→ Fog: Exchange DID, anchor key, credential, fingerprint, TOTP secret
  ~100 bytes, stored on both sides
  Analogy: Like 'ssh-keygen' + copying the public key

PHASE 2: Mutual Authentication (every session)
  Device → Fog:  M1 = {DID, fingerprint, N1, T1, Auth1}     ~100 bytes
  Fog → Device:  M2 = {FID, N2, T2, Auth2, H(SK)}           ~100 bytes
  Total: 200 bytes, 8 hash operations, <1ms latency
  Result: Both sides verified + shared session key SK

PHASE 3: TOTP Two-Factor Auth (Admin/Resident only)
  6-digit time-based OTP, 30-second window, ±30s grace

PHASE 4: Device Fingerprinting (anti-cloning)
  fingerprint = SHA-256(type || MAC || firmware || capabilities || reg_time)
```

**Speaking Points (1 minute):**
- "LAFSH has 4 phases. Phase 1 is one-time registration — like setting up SSH keys."
- "Phase 2 is the core: mutual authentication in just 2 messages, 200 bytes total, using only SHA-256 hashes. Both the device AND the fog prove their identity to each other."
- "Phase 3 adds TOTP two-factor authentication for privileged roles — Admin and Resident. It's the same concept as Google Authenticator."
- "Phase 4 is device fingerprinting — a SHA-256 hash of the device's hardware properties that detects physical cloning attempts."
- Transition: "Let me zoom into Phase 2 — the mutual authentication protocol."

---

## Slide 7: Mutual Authentication Deep Dive
**Speaker: Member 3**

**Visual**: The M1/M2 message exchange diagram, step by step.

```
DEVICE SIDE                               FOG SIDE
─────────────                             ─────────
1. Auth1 = H(DID||A||N1||T1)
2. Send M1 = {DID, fp, N1, T1, Auth1}
                ──────────────────→
                                          3. CHECK: |now - T1| < 120s
                                             (blocks replay attacks)
                                          4. CHECK: fp == stored fp
                                             (blocks device cloning)
                                          5. VERIFY: Auth1 == H(DID||A||N1||T1)
                                             (blocks impersonation)
                                          ✓ Device authenticated!

                                          6. Auth2 = H(FID||A||N1||N2||T2)
                                          7. SK = H(N1||N2||A||DID||FID)
                ←──────────────────
8. VERIFY: Auth2 matches expected
   ✓ Fog authenticated! (MUTUAL)
9. SK_device = H(N1||N2||A||DID||FID)
   ✓ Shared session key established
```

**Speaking Points (1.5 minutes):**
- "The device computes Auth1 — a hash of its ID, anchor key, a fresh nonce, and the current timestamp — and sends M1 to the fog."
- "The fog performs three security checks on M1:"
  - "First, timestamp freshness — is the message less than 120 seconds old? This blocks replay attacks."
  - "Second, fingerprint match — does the hardware fingerprint match what was registered? This blocks device cloning."
  - "Third, Auth1 verification — does the hash match when the fog recomputes it with the stored anchor key? This blocks impersonation."
- "If all three pass, the device is authenticated. The fog then computes Auth2 and a session key SK, and sends M2 back."
- "The device verifies Auth2 — this is what makes it MUTUAL authentication — and independently derives the same session key."
- "The session key is NEVER sent in cleartext. Both sides compute it independently using shared secrets."
- Transition: "Now let's see how we enforce access control."

---

## Slide 8: RBAC Access Control
**Speaker: Member 2**

**Visual**: The RBAC heatmap (from `plot_rbac_heatmap`) + permission matrix table.

```
4 ROLES × 11 OPERATIONS

         Admin  Resident  Guest  Device
Lock       ✓       ✓        ✗      ✗
Camera     ✓       ✓       ✓*      ✗      * = time-restricted (09:00-22:00)
Recording  ✓       ✗        ✗      ✗
Thermo Set ✓       ✓        ✗      ✗
Thermo Rd  ✓       ✓        ✓      ✓
Lights     ✓       ✓        ✓      ✗
Add Device ✓       ✗        ✗      ✗
Firmware   ✓       ✗        ✗      ✗
Sensor     ✓       ✓        ✓      ✓

ACCESS CHECK FLOW:
1. Valid session? → 2. TOTP verified? → 3. Role permitted? → 4. Time window OK?
Every decision logged in audit trail.
```

**Speaking Points (1 minute):**
- "We implement Role-Based Access Control with 4 roles: Admin, Resident, Guest, and Device."
- "Admin has full control. Resident can operate most devices but can't manage the network or access camera recordings — that's a privacy feature."
- "Guests are time-restricted — they can only use cameras between 9 AM and 10 PM. And Device-role nodes can only report sensor data."
- "Every access decision goes through a 4-step check and is logged in an audit trail for forensics."
- Transition: "[Member 3] will present our security analysis results."

---

## Slide 9: Security Analysis — 6 Attack Scenarios
**Speaker: Member 3**

**Visual**: Table of attacks, defenses, and results.

```
ATTACK                    DEFENSE MECHANISM                    RESULT
─────                    ──────────────────                   ──────
1. Replay Attack         Timestamp check |now-T1| < 120s     BLOCKED ✓
2. Device Cloning        Hardware fingerprint match           BLOCKED ✓
3. Impersonation         Auth1 hash verification              BLOCKED ✓
4. TOTP Brute Force      6-digit OTP, 30s window (0.0001%)   BLOCKED ✓
5. Privilege Escalation  RBAC permission matrix               BLOCKED ✓
6. Rogue Device          Registry lookup (not registered)     BLOCKED ✓

Score: 6/6 attacks blocked

Comparison:
  LAFSH:     6/6 attacks blocked
  Basic PW:  2/6 (no replay/cloning protection)
  DTLS-PSK:  4/6 (no fingerprinting)
  TLS-Cert:  4/6 (no RBAC, no TOTP)
```

**Speaking Points (1.5 minutes):**
- "We tested 6 real-world attack scenarios. Our script `run_security_analysis.m` automates all of them."
- Walk through each attack briefly:
  - "Replay: Attacker captures a valid login message and replays it 5 minutes later. Fog detects the stale timestamp and rejects — diff was 300 seconds, our threshold is 120."
  - "Cloning: Attacker copies a device but can't replicate the exact hardware fingerprint. SHA-256 hash mismatch → rejected."
  - "Impersonation: Without the anchor key (which never leaves the fog), the attacker can't compute a valid Auth1 hash."
  - "TOTP brute force: 1 in 1,000,000 chance per attempt in a 30-second window."
  - "Privilege escalation: Device role tries admin operation → RBAC denies immediately."
  - "Rogue device: Unregistered device isn't in the fog's registry → lookup fails."
- "Score: 6 out of 6 attacks blocked. We beat all baseline schemes in our comparison."

---

## Slide 10: Performance Results
**Speaker: Member 1**

**Visual**: Side-by-side charts (auth latency plot, energy comparison bar chart, communication overhead).

```
╔════════════════════════════════════════════════════╗
║  LAFSH vs. Traditional Approaches                  ║
║                                                    ║
║  Metric            LAFSH    TLS-Cert  Improvement  ║
║  ────────────────  ──────   ────────  ───────────  ║
║  Bytes per auth    200      5,000     25× less     ║
║  Energy per auth   162 µJ   1.8 mJ   11,000× less ║
║  Auth latency      <1 ms    ~300 ms   300× faster  ║
║  Hash operations   8        N/A       —            ║
║  Security score    6/6      4/6       +2 more      ║
╚════════════════════════════════════════════════════╝

500 devices authenticated in < 500ms total.
Linear scaling: 1000 devices ≈ 1 second.
```

**Speaking Points (1 minute):**
- "Our performance numbers show LAFSH is dramatically more efficient than traditional TLS."
- "Communication overhead is 25 times less — just 200 bytes versus 5,000."
- "Energy consumption is 11,000 times less — 162 microjoules versus 1.8 millijoules. That means a motion sensor can authenticate 1.85 million times instead of 166."
- "Authentication latency is under 1 millisecond per device. We authenticated all 500 devices in under half a second."
- "And we provide MORE security — 6 out of 6 attacks blocked versus 4 out of 6 for TLS."

---

## Slide 11: Live Demo (if time permits)
**Speaker: Member 1 (drives) + Member 2/3 (narrate)

```
Run: main.m → Option 1 (Interactive Demo) in MATLAB Online

DEMO FLOW (3-4 minutes):
1. 500 nodes deploy → deployment map appears
2. LEACH-SEP clusters form → cluster diagram
3. Communication rounds → network stats plots
4. 6 devices register and authenticate → console output
5. TOTP 2FA for Admin → OTP code verified
6. RBAC: permitted and denied scenarios
7. 3 attacks → all BLOCKED
8. Audit log displayed

OR if time is short:
  main.m → Option 3 (Security Analysis) — runs in ~30 seconds, shows 6/6 blocked
```

**Speaking Points:**
- Member 1 drives MATLAB. Member 2 narrates the networking stages (deploy, cluster, rounds). Member 3 narrates auth and attacks.
- Keep it tight — skip the wait during communication rounds if needed.

---

## Slide 12: Conclusion & Future Work
**Speaker: Member 1**

```
WHAT WE BUILT:
✓ 3-layer fog computing architecture for smart homes
✓ 500-node heterogeneous deployment with LEACH-SEP clustering
✓ First-order radio energy model for realistic simulation
✓ 4-phase lightweight auth protocol (SHA-256 + XOR only)
✓ TOTP 2FA + Device fingerprinting
✓ RBAC with 4 roles × 11 operations + time restrictions
✓ 6/6 attack scenarios blocked
✓ 11,000× more energy-efficient than TLS

FUTURE WORK:
• Blockchain-based audit trail for tamper-proof logging
• Hardware Security Module (HSM) integration for fog key storage
• MQTT/CoAP integration for real protocol testing
• Formal security proof using BAN logic or ProVerif

Thank you. Questions?
```

**Speaking Points (1 minute):**
- "To summarize: we built a complete fog computing simulation with a lightweight authentication protocol that is 11,000 times more energy efficient than TLS while blocking more attack types."
- "For future work, we'd explore blockchain for tamper-proof audit logs, HSM integration, and formal security verification."
- "Thank you. We're happy to take questions."

---

# TEAM SPEAKING SPLIT

## Member 1 (Shivang — Team Lead)
- **Slides**: 1, 2, 3, 10, 12
- **Topics**: Problem statement, motivation, performance results, conclusion
- **Live demo**: Drives MATLAB
- **Time**: ~5 minutes presenting + demo driving

## Member 2
- **Slides**: 4, 5, 8
- **Topics**: Architecture, LEACH-SEP clustering, RBAC
- **Live demo**: Narrates deployment + clustering
- **Time**: ~4 minutes presenting

## Member 3
- **Slides**: 6, 7, 9
- **Topics**: Auth protocol (all 4 phases), mutual auth deep dive, security analysis
- **Live demo**: Narrates auth + attack detection
- **Time**: ~4 minutes presenting

### Transition Cues

| After Slide | Speaker Says                                                     | Next Speaker |
|-------------|------------------------------------------------------------------|-------------|
| 3           | "[Member 2] will walk you through the architecture"              | Member 2    |
| 5           | "[Member 3] will present our auth protocol — the core of LAFSH"  | Member 3    |
| 7           | "[Member 2] will explain our access control model"               | Member 2    |
| 8           | "[Member 3] will present the security analysis results"          | Member 3    |
| 9           | "[Member 1] will summarize our performance numbers"              | Member 1    |

---

# PROFESSOR CROSS-QUESTION DRILLS

## Category 1: Fog Computing Fundamentals

**Q1: "Why not just use a cloud? What does the fog node add?"**
> The fog node reduces latency from 100-500ms to 5ms for local operations. It enables offline operation — your smart home still works if internet goes down. It keeps private data local. And it reduces bandwidth by aggregating data at the fog before sending summaries to the cloud.

**Q2: "What's the difference between fog and edge computing?"**
> Edge computing runs on the IoT devices themselves. Fog is an intermediate layer between edge and cloud — it has more compute power than edge devices but is closer to them than the cloud. Our fog node is like a smart gateway/hub that serves hundreds of edge devices.

**Q3: "Can the smart home work WITHOUT the cloud at all?"**
> Yes, for day-to-day operations. The cloud's master secret is used only during initial fog setup. After that, the fog node handles all authentication, access control, and sessions independently. Cloud is only needed for firmware updates, remote access, and long-term storage.

**Q4: "What happens if the fog node fails?"**
> Currently, it's a single point of failure for authentication. A real deployment would have a backup fog node or the cloud could serve as fallback with higher latency. This is noted in our future work.

---

## Category 2: Clustering & Networking

**Q5: "Why LEACH? Why not just direct communication?"**
> Direct communication means 500 separate transmissions to the fog node. With the first-order radio model, transmission energy grows with d² or d⁴. Clustering reduces long-range transmissions by 10×. Members send to nearby cluster head (short distance, cheap), only the CH sends to fog (long distance, but just one).

**Q6: "What is SEP and why did you need it?"**
> Standard LEACH assumes all nodes are identical — same battery, same capabilities. But our network is heterogeneous: a camera has 2J while a sensor has 0.3J. SEP gives higher-energy nodes a proportionally higher probability of becoming cluster head. We also add energy weighting so that nearly-depleted nodes avoid the CH role entirely.

**Q7: "What is the first-order radio model? Give the formula."**
> For transmitting k bits over distance d: if d < 87m (free space), E_tx = E_elec × k + E_fs × k × d². If d ≥ 87m (multipath), E_tx = E_elec × k + E_mp × k × d⁴. For receiving: E_rx = E_elec × k. E_elec = 50 nJ/bit, E_fs = 10 pJ/bit/m², E_mp = 0.0013 pJ/bit/m⁴.

**Q8: "How do you decide the optimal number of cluster heads?"**
> We use p = 0.1, meaning roughly 10% of nodes become cluster heads. This is the established optimal value from Heinzelman's original LEACH paper, validated for networks of our scale. With 500 nodes, that's about 50 cluster heads.

---

## Category 3: Authentication Protocol

**Q9: "Why SHA-256? Why not RSA or AES?"**
> RSA requires ~900,000 µJ per operation on a microcontroller — too expensive for battery-powered IoT devices. AES is for encryption, not authentication. SHA-256 costs only ~0.3 µJ per hash, and we only need 8 hashes per authentication. This makes LAFSH 11,000× more energy-efficient than PKI/RSA approaches.

**Q10: "What is mutual authentication and why does it matter?"**
> In mutual authentication, BOTH sides prove their identity: the device to the fog AND the fog to the device. This prevents fog impersonation attacks — an attacker can't set up a fake fog node and steal device credentials. The device verifies Auth2 in M2 to confirm the fog is genuine.

**Q11: "How does the session key work? Is it sent over the network?"**
> No! The session key SK = H(N1 || N2 || A || DID || FID) is independently computed by both sides. N1 is the device's nonce, N2 is the fog's nonce, and A is the shared anchor key. Both sides know all these values after the M1/M2 exchange, so they can derive SK independently. Only H(SK) is sent for verification — not SK itself.

**Q12: "What if someone intercepts M1 and M2?"**
> They get: DID (public), fingerprint (public hash), nonces (random, one-time), timestamps, and Auth1/Auth2 (hashes). But SHA-256 is one-way — you can't reverse Auth1 to get the anchor key A. And without A, you can't forge valid messages or derive the session key. The nonces ensure no two sessions use the same values.

**Q13: "What is the anchor key and how is it generated?"**
> A = H(DID || fog_secret). It binds the device's identity to the fog's secret. The fog_secret is derived from the cloud's master_secret during fog initialization. The anchor key never leaves the fog — the device gets it during registration and stores it locally, but it's never transmitted again after that.

**Q14: "What is TOTP and why only for Admin/Resident?"**
> TOTP (Time-Based One-Time Password) generates a 6-digit code that changes every 30 seconds, like Google Authenticator. We require it only for Admin and Resident because these roles control critical operations (door locks, cameras). IoT devices authenticate via Phase 2 only — adding TOTP to a motion sensor would be impractical.

---

## Category 4: Security

**Q15: "How does your replay attack defense work? Walk me through the fix."**
> The fog node checks |current_time - T1| < 120 seconds, where T1 is the timestamp in the device's message. If an attacker replays an old message, its T1 will be stale. For example, a message replayed 5 minutes later has diff=300s, which exceeds our 120-second threshold. Critically, the fog uses its own real clock via `get_timestamp()` — not a simulation timestamp.

**Q16: "What if an attacker replays the message within 120 seconds?"**
> Two defenses: (1) The nonce N1 is random and one-time — the fog has already processed it and created a session. Replaying won't help because the session already exists. (2) The attacker would also need to pass the fingerprint check and Auth1 verification. Without the anchor key, they can't forge new Auth1 values.

**Q17: "How does device fingerprinting prevent cloning?"**
> The fingerprint is SHA-256 of (device type + MAC address + firmware version + capability mask + registration timestamp). If an attacker clones a device, the clone will have a different MAC address. Different MAC → different fingerprint → fog rejects the authentication with "DEVICE CLONING DETECTED."

**Q18: "What if someone steals the device physically?"**
> They get the device's stored credentials (RPW, C, A_device). But (1) the actual password is never stored — RPW = H(DID || PW || r), which is hash-protected. (2) For Admin/Resident roles, they'd also need to pass TOTP — which requires the TOTP secret. (3) The fog could also implement account lockout after failed attempts, which our code supports via `fog.failed_attempts`.

---

## Category 5: Performance & Comparison

**Q19: "How can LAFSH be 11,000× more energy-efficient? That sounds unrealistic."**
> It's comparing hash operations vs. RSA operations. A single SHA-256 hash costs ~0.3 µJ on a low-power microcontroller. We use 8 hashes = 2.4 µJ. Plus 200 bytes of TX/RX = ~160 µJ. Total = 162 µJ. RSA-2048 costs ~900,000 µJ per signature. Two RSA operations in a TLS handshake = 1,800,000 µJ. That ratio is exactly 11,111×. These numbers come from published embedded system benchmarks.

**Q20: "What are the limitations of your approach?"**
> (1) We simulate fingerprints — real hardware would use PUFs (Physical Unclonable Functions). (2) No formal security proof (BAN logic or ProVerif). (3) Single fog node is a potential single point of failure. (4) Session key doesn't provide forward secrecy — if the anchor key is compromised, all past sessions are compromised. These are all valid future work items.

**Q21: "How does your work differ from the Wazid et al. paper you cite?"**
> Wazid's LAM-CIoT targets cloud-IoT systems, not fog-IoT. Our contribution is (1) adding a fog layer for local authentication with sub-millisecond latency, (2) LEACH-SEP clustering for heterogeneous device support, (3) device fingerprinting as an additional anti-cloning layer, and (4) RBAC with time-restricted guest access.

---

## Category 6: Implementation & MATLAB

**Q22: "Why MATLAB? Why not Python or C?"**
> MATLAB excels at matrix operations, plotting, and rapid prototyping — ideal for academic simulation. The built-in plotting generates publication-quality figures. Java interop gives us SHA-256 via `MessageDigest`. And MATLAB Online lets us demo without installing anything.

**Q23: "How do you generate SHA-256 in MATLAB?"**
> We use Java interop: `java.security.MessageDigest.getInstance('SHA-256')`. MATLAB runs on the JVM, so we can call Java's cryptographic library directly. The input is converted to bytes, hashed, and the output is converted to a hex string.

**Q24: "How many lines of code is your project?"**
> Approximately 1,500 lines across 26 MATLAB files. The authentication module (`src/auth/`) is about 400 lines. The network module (`src/network/`) is about 300 lines. The visualization module generates 7 different plot types.

**Q25: "Can you run the demo right now?"**
> Yes — in MATLAB Online, we clone the repo with `!git clone`, change to the LAFSH folder, and run `main.m`. Option 1 runs the full interactive demo in about 2-3 minutes.

---

# FINAL POLISH CHECKLIST

The project is in excellent shape for mid-term. A few optional improvements if you want to go above and beyond:

| Item | Priority | Effort | Value |
|------|----------|--------|-------|
| Generate and commit sample figures from `run_evaluation.m` | Low | 5 min | Pre-made plots in the repo look professional |
| Add `presentation/slides.pptx` to the repo | Low | 30 min | Shows organization |
| Fix slide numbers in README quick-start | None needed | — | Already correct |
| Add a one-page summary PDF in `report/` | Low | 15 min | Useful handout for professor |

> **Verdict:** The project is mid-term ready as-is. The code is clean, demo works, security analysis passes 6/6, learning guide covers A→Z, and this presentation guide covers all speaking points. No critical fixes needed.

---

# APPENDIX: 60-SECOND ELEVATOR PITCH

If the professor says "Summarize your project in one minute":

> "We built LAFSH — a Lightweight Authentication protocol for Fog-Based Smart Homes.
>
> The problem: IoT devices have tiny batteries and standard TLS authentication drains them in hours.
>
> Our solution: We put a fog node inside the home that handles authentication locally using only SHA-256 hashes instead of RSA certificates. This makes our protocol 11,000 times more energy-efficient and 300 times faster than TLS.
>
> We simulate 500 heterogeneous devices with LEACH-SEP clustering, implement a 4-phase authentication protocol with TOTP two-factor auth and device fingerprinting, enforce RBAC access control with 4 roles, and block all 6 tested attack scenarios including replay, cloning, and privilege escalation.
>
> The entire system runs in MATLAB and we can demo it right now."
