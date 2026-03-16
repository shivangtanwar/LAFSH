# LAFSH Mid-Term Presentation Guide
## Aligned to Mid-Term Evaluation Criteria (18-20 Mar)

---

# EVALUATION CRITERIA → SLIDE MAPPING

| # | Evaluation Criterion | Slides |
|---|---------------------|--------|
| 1 | MATLAB setup | Slide 2 |
| 2 | Nodes deployment (300-1000, heterogeneous) | Slides 3-4 |
| 3 | Communication between nodes | Slide 5 |
| 4 | Cluster formation with cluster heads (best algorithm) | Slides 6-7 |
| 5 | Work done as per project | Slides 8-9 |
| 6 | 4-5 page report (intro, lit survey, implementation) | `report/midterm_report.txt` ✅ already done |

---

# SLIDE STRUCTURE (10 Slides)

**Total time**: 12-15 minutes + Q&A

---

## Slide 1: Title
**Speaker: Member 1 (Shivang)**

```
LAFSH: Lightweight Authentication for Fog-Based Smart Homes

CSE4702 — Fog Computing | BTech 3rd Year, Semester 6
Team: [Name 1], [Name 2], [Name 3]
GitHub: github.com/shivangtanwar/LAFSH
```

**Say (30s):**
- "Our project is LAFSH — a Lightweight Authentication protocol for Fog-Based Smart Homes, simulated entirely in MATLAB."
- "Today we'll walk through our MATLAB setup, heterogeneous deployment, communication model, clustering, and the authentication work we've built on top."

---

## Slide 2: MATLAB Setup & Architecture
**Speaker: Member 1**

**Visual**: Three-layer architecture diagram + MATLAB Online screenshot.

```
ENVIRONMENT:
• MATLAB Online (no install needed) or MATLAB R2020b+
• No additional toolboxes required
• Java interop for SHA-256 (java.security.MessageDigest)
• 26 MATLAB files across 7 modules

THREE-LAYER ARCHITECTURE:
┌─────────────────────────────────┐
│  CLOUD — Master secrets, policy │     ← init_cloud.m
├─────────────────────────────────┤
│  FOG — Local gateway/hub       │     ← init_fog_node.m
│  Auth · RBAC · Sessions        │
├─────────────────────────────────┤
│  EDGE — 500 IoT devices        │     ← deploy_nodes.m
│  6 types, battery-powered      │
└─────────────────────────────────┘

Entry points: main.m → run_demo.m / run_evaluation.m / run_security_analysis.m
```

**Say (1 min):**
- "We run on MATLAB Online — zero setup, just clone the repo and run `main.m`."
- "No toolboxes needed. We use Java interop for SHA-256 hashing."
- "Our architecture has three layers: Cloud for master secrets, Fog node as the local gateway handling authentication and access control, and the Edge layer with 500 heterogeneous IoT devices."
- Transition: "[Member 2] will show you our node deployment."

---

## Slide 3: Heterogeneous Node Deployment
**Speaker: Member 2**

**Visual**: Deployment scatter plot (from `plot_deployment`) — show during live demo if possible.

```
deploy_nodes(500, 200)  →  500 devices in 200m × 200m area

DEVICE MIX (HETEROGENEOUS):
Type            Count   %     Energy      Range    Data Rate
Smart Lights    150    30%    0.3-0.6J    15m      10 B/s
Thermostats     100    20%    0.5-1.0J    20m      20 B/s
IP Cameras       75    15%    1.0-2.0J    30m      500 B/s
Smart Locks      75    15%    0.5-1.0J    20m      15 B/s
Motion Sensors   50    10%    0.2-0.4J    10m      5 B/s
Smart Plugs      50    10%    0.3-0.5J    15m      10 B/s

Each device gets: x,y position, initial_energy, comm_range,
data_rate, MAC address, capability_mask, fingerprint
```

**Say (1.5 min):**
- "We deploy 500 nodes — well within the 300-1000 range — across a 200m × 200m area."
- "The deployment is **heterogeneous**: six different device types with different energy levels, communication ranges, and data rates."
- "A camera has 2 joules and 30-metre range. A motion sensor has only 0.3 joules and 10-metre range. This heterogeneity is critical — it's what makes our clustering algorithm necessary."
- "Every device gets a unique MAC address, position, and hardware fingerprint."

---

## Slide 4: Why Heterogeneous Matters
**Speaker: Member 2**

```
HOMOGENEOUS (basic LEACH):
  All 500 nodes identical → same CH probability
  Problem: motion sensor (0.3J) becomes CH as often as camera (2.0J)
  → sensor dies 7× faster → network lifetime drops

HETEROGENEOUS (our LEACH-SEP):
  Different device types → different energy profiles
  High-energy nodes become CH more often
  Low-energy nodes conserve battery
  → Fair energy distribution → longer network lifetime

REAL-WORLD RELEVANCE:
  No real smart home has identical devices.
  Showing heterogeneity = deeper understanding of fog/IoT networks.
```

**Say (1 min):**
- "If all nodes were identical, a tiny sensor and a powerful camera would have the same chance of becoming cluster head. The sensor dies 7 times faster — that's unfair and kills network lifetime."
- "Our heterogeneous deployment reflects real smart homes. Different device types have genuinely different energy and capability profiles."
- "This is why we need LEACH-SEP instead of basic LEACH — we'll explain that in the clustering slides."
- Transition: "First, let [Member 3] explain how devices actually communicate."

---

## Slide 5: Communication Between Nodes (First-Order Radio Model)
**Speaker: Member 3**

**Visual**: Energy model diagram + formula.

```
FIRST-ORDER RADIO ENERGY MODEL (Heinzelman et al., 2000):

TRANSMIT k bits over distance d:
  if d < 87m:  E_tx = E_elec×k + E_fs×k×d²      (free space)
  if d ≥ 87m:  E_tx = E_elec×k + E_mp×k×d⁴      (multipath)

RECEIVE k bits:
  E_rx = E_elec × k

Constants: E_elec = 50 nJ/bit, E_fs = 10 pJ/bit/m², E_mp = 0.0013 pJ/bit/m⁴

KEY INSIGHT: Energy grows with d² or d⁴
  10m transmission  →  cheap
  150m transmission →  ~500 million × more expensive per bit

COMMUNICATION FLOW PER ROUND:
  Step 1: Members → Cluster Head (128 bytes, short distance)
  Step 2: CH aggregates data (E_DA = 5 nJ/bit/signal)
  Step 3: CH → Fog Node (256 bytes, long distance)
```

**Say (1.5 min):**
- "We use the standard first-order radio energy model from Heinzelman — the same group that invented LEACH."
- "Transmitting k bits costs electronics energy plus amplifier energy. Below 87 metres, it's free-space propagation — energy grows with distance squared. Above 87 metres, it's multipath — energy grows with distance to the fourth power."
- "This is the fundamental reason clustering saves energy: members send to a nearby cluster head — short distance, cheap. Only the cluster head sends the aggregated data to the far-away fog node."
- "Each round, members send 128 bytes to CH, CH aggregates and fuses data, then sends 256 bytes to the fog."
- Transition: "Now [Member 2] will explain how we form these clusters."

---

## Slide 6: LEACH-SEP Cluster Formation
**Speaker: Member 2**

**Visual**: Cluster visualization (from `plot_clusters`) + threshold formula.

```
WHY CLUSTER?
  Without: 500 devices → 500 direct TX to fog   (expensive!)
  With:    500 devices → ~50 CHs → fog           (10× fewer long-range TX)

LEACH BASE THRESHOLD:
  T(n) = p / (1 - p × mod(r, 1/p))
  p = 0.1 (10% CH target), r = round number

SEP ENHANCEMENT FOR HETEROGENEOUS NETWORKS:
  α = (avg_energy_advanced / avg_energy_normal) - 1

  p_normal   = p_opt / (1 + (N_adv/N) × α)     ← lower probability
  p_advanced = p_normal × (1 + α)               ← higher probability

ENERGY WEIGHTING:
  threshold = T(n) × (E_residual / E_initial)
  Node at 80% battery → 80% of base threshold
  Node at 10% battery → almost never becomes CH

RESULT: Energy-fair, heterogeneity-aware cluster head rotation
```

**Say (1.5 min):**
- "Without clustering, 500 devices all transmit directly to the fog — 500 expensive long-range transmissions per round."
- "With LEACH clustering, we elect about 50 cluster heads. Non-CH nodes join the nearest CH. So we get 10× fewer long-range transmissions."
- "Standard LEACH uses a probabilistic threshold for CH election and rotates every few rounds. But it assumes homogeneous nodes."
- "SEP extends LEACH by classifying nodes as advanced or normal based on energy. Advanced nodes get a higher election probability — so cameras become CH more often than sensors."
- "We also multiply the threshold by the ratio of residual to initial energy. A node at 10% battery almost never becomes CH."

---

## Slide 7: Cluster Communication Results
**Speaker: Member 3**

**Visual**: Network stats plots (from `plot_network_stats`) — alive nodes, energy consumed, PDR.

```
SIMULATION: 50 communication rounds, re-cluster every 10 rounds

LIVE DEMO OUTPUT:
  Round 10: ~498 alive, ~0.01J consumed, PDR≈99%
  Round 20: ~495 alive, ~0.02J consumed, PDR≈98%
  Round 30: ~490 alive, ~0.04J consumed, PDR≈97%
  Round 40: ~485 alive, ~0.06J consumed, PDR≈96%
  Round 50: ~480 alive, ~0.08J consumed, PDR≈95%

NETWORK STATS PLOTS GENERATED:
  - Alive nodes vs. round number
  - Total energy consumed vs. round
  - Packet delivery ratio vs. round
  - Per-round energy breakdown
```

**Say (1 min):**
- "We run 50 communication rounds with re-clustering every 10 rounds — following the LEACH protocol."
- "The network stats show gradual, fair energy depletion. After 50 rounds, about 480 out of 500 nodes are still alive."
- "Packet delivery ratio stays above 95%. The SEP enhancement ensures no single device type dies off disproportionately."
- Transition: "[Member 1] will now show the additional project work we've built on top of this network layer."

---

## Slide 8: Project Work Done — LAFSH Auth Protocol
**Speaker: Member 1**

```
BEYOND NETWORKING — WHAT WE'VE BUILT ON TOP:

4-PHASE AUTHENTICATION:
  Phase 1: Device registration (one-time, anchor key + credential)
  Phase 2: Mutual auth in 2 messages, 200 bytes, 8 hash ops, <1ms
  Phase 3: TOTP 2FA for Admin/Resident (6-digit, 30-second)
  Phase 4: Device fingerprinting for anti-cloning

ACCESS CONTROL:
  RBAC: 4 roles (Admin/Resident/Guest/Device) × 11 operations
  Time-restricted guest access (09:00-22:00)
  Full audit logging

SECURITY ANALYSIS:
  6/6 attacks blocked: replay, cloning, impersonation,
  TOTP brute-force, privilege escalation, rogue device

PERFORMANCE vs TLS:
  Communication: 200 bytes vs 5,000 (25× less)
  Energy: 162 µJ vs 1.8 mJ (11,000× less)
  Latency: <1ms vs ~300ms (300× faster)
```

**Say (1.5 min):**
- "On top of the networking layer, we've implemented the full LAFSH authentication protocol."
- "It has 4 phases: registration, mutual authentication, TOTP two-factor auth, and device fingerprinting."
- "The key metric: 200 bytes and 162 microjoules per authentication — that's 11,000 times more efficient than TLS."
- "We also built RBAC access control with 4 roles and 11 operations, and a security analysis that blocks all 6 tested attack scenarios."
- "We can demo any of this live in MATLAB Online."

---

## Slide 9: Live Demo
**Speaker: Member 1 drives, Member 2 + 3 narrate**

```
IN MATLAB ONLINE:
  >> main.m → Option 1 (Interactive Demo)

DEMO FLOW (3-5 min):
  1. System init (cloud, fog)             ← quick, <1s
  2. 500 nodes deploy → scatter plot       ← SHOW deployment map
  3. LEACH-SEP clusters → cluster diagram  ← SHOW cluster formation
  4. 50 communication rounds → stats plots ← SHOW network stats
  5. Device registration                   ← console output
  6. Mutual auth + TOTP                    ← console output
  7. 3 attacks → all BLOCKED               ← KEY MOMENT
  8. Audit log                             ← console output

BACKUP (if time is short):
  >> main.m → Option 5 (Quick Test) — 300 nodes, cluster, visualize in 30s
```

**Say:**
- Member 1 drives MATLAB. Member 2 narrates steps 2-4 (deploy, cluster, rounds). Member 3 narrates steps 5-7 (auth, attacks).
- Point out the heterogeneous node types in the scatter plot (different colors).
- Point out "Attacks blocked: 3/3" at the end.

---

## Slide 10: Conclusion
**Speaker: Member 1**

```
MID-TERM DELIVERABLES — ALL MET:

✓ MATLAB setup ready (MATLAB Online, no toolboxes)
✓ 500 heterogeneous nodes deployed (6 types, 300-1000 range)
✓ Communication using first-order radio energy model
✓ LEACH-SEP clustering with energy-aware CH election
✓ Full LAFSH auth protocol + RBAC + security analysis
✓ 4-5 page report with intro, lit survey, implementation

ADDITIONAL WORK BEYOND MID-TERM SCOPE:
• TOTP 2FA, device fingerprinting
• 6/6 attack scenarios tested and blocked
• Performance evaluation suite with 5 plot types
• Complete learning guide for team prep

Thank you. Questions?
```

**Say (45s):**
- "To summarize: we've met all six mid-term criteria. MATLAB is set up, 500 heterogeneous nodes deployed, communication modeled, LEACH-SEP clustering implemented, and the report is ready."
- "Beyond mid-term scope, we've also completed the full authentication protocol, RBAC, and security analysis — which sets us up well for end-term."
- "Thank you. We're happy to take questions."

---

# TEAM SPEAKING SPLIT

| Member | Slides | Topics | Time |
|--------|--------|--------|------|
| **Member 1 (Shivang)** | 1, 2, 8, 10 + demo driver | Title, MATLAB setup, project work, conclusion | ~4 min + demo |
| **Member 2** | 3, 4, 6 | Deployment, heterogeneity, clustering | ~4 min |
| **Member 3** | 5, 7 | Communication model, cluster round results | ~3 min |

### Transition Cues

| After Slide | Say | Next |
|-------------|-----|------|
| 2 | "[Member 2] will show our node deployment" | Member 2 |
| 4 | "[Member 3] will explain the communication model" | Member 3 |
| 5 | "[Member 2] will explain cluster formation" | Member 2 |
| 6 | "[Member 3] will show the communication round results" | Member 3 |
| 7 | "[Member 1] will present the additional project work" | Member 1 |

---

# PROFESSOR CROSS-QUESTION DRILLS

## Networking & Clustering (PRIMARY FOCUS)

**Q1: "Why LEACH? Why not PEGASIS or TEEN?"**
> LEACH is the most established clustering protocol for WSN — well-studied, simple to implement, and scalable. PEGASIS is chain-based (not cluster-based) and has higher latency. TEEN is threshold-based and only works for reactive networks. LEACH-SEP specifically handles heterogeneous networks, which matches our smart home scenario.

**Q2: "What does SEP add to LEACH?"**
> Standard LEACH assumes all nodes have equal energy — same CH probability for a camera (2J) and a sensor (0.3J). SEP classifies nodes as advanced/normal and gives higher-energy nodes proportionally higher CH election probability. We also add energy weighting: threshold × (residual/initial). This prevents depleted nodes from becoming CH.

**Q3: "Give me the LEACH threshold formula."**
> T(n) = p / (1 - p × mod(r, 1/p)), where p=0.1 is the target CH percentage and r is the round number. With SEP, we use p_advanced and p_normal instead of a single p. Then we multiply by (E_residual / E_initial) for energy awareness.

**Q4: "Why 10% cluster heads? Why not 5% or 20%?"**
> 10% (p=0.1) is the optimal value from Heinzelman's original LEACH paper, validated empirically for networks of 100-1000 nodes. With 500 nodes, ~50 CHs gives a good balance: enough clusters for coverage, few enough to reduce long-range transmissions.

**Q5: "What is the first-order radio model? Why use it?"**
> It's the standard energy model from Heinzelman 2000. E_tx = E_elec×k + E_amp×k×d^n, where n=2 for short distances (free space) and n=4 for long distances (multipath). E_rx = E_elec×k. We use it because it's the established model in WSN literature — used alongside LEACH in almost every energy-efficiency paper.

**Q6: "Why re-cluster every 10 rounds instead of every round?"**
> Cluster formation has its own energy cost — nodes exchange advertisements. Re-clustering too often wastes energy on overhead. Too rarely means CH energy gets depleted unfairly. 10 rounds is a standard LEACH rotation interval that balances overhead against fairness.

**Q7: "What is network lifetime and how does your system perform?"**
> Network lifetime is typically defined as rounds until the first node dies, or until 50% of nodes die. Our LEACH-SEP extends lifetime significantly compared to basic LEACH because high-energy nodes absorb more CH duty, protecting low-energy sensors.

**Q8: "How does data aggregation work?"**
> The cluster head fuses data from all its members into a compressed summary. Energy cost: E_DA = 5 nJ/bit/signal. For example, 10 members sending 128 bytes each → CH aggregates into one 256-byte packet sent to the fog. This is why clustering reduces bandwidth: 10 transmissions compressed into 1.

## Fog Computing Fundamentals

**Q9: "What is fog computing? How is it different from cloud?"**
> Fog computing places compute closer to IoT devices — at the network edge. Unlike cloud (100-500ms away), the fog node is local (5-10ms). It enables low-latency operations, works offline, keeps data local for privacy, and reduces bandwidth by aggregating data before sending summaries to the cloud.

**Q10: "Why not just use the cloud for everything?"**
> Three reasons: (1) Latency — 200ms to unlock a door is too slow. (2) Reliability — internet outage means nothing works. (3) Bandwidth — 500 devices all uploading to cloud is expensive. The fog handles 95% of operations locally.

**Q11: "Can the system work without the cloud?"**
> Yes, for day-to-day operations. The cloud only provides the initial master secret during fog setup. After that, the fog handles all authentication, access control, and sessions independently.

## Authentication (SECONDARY — if professor probes deeper)

**Q12: "Why SHA-256 instead of RSA?"**
> RSA-2048 costs ~900,000 µJ per operation on a microcontroller. SHA-256 costs ~0.3 µJ. Our protocol uses 8 hashes per auth = 2.4 µJ. That's 11,000× less energy than RSA. For battery-powered IoT devices, this difference is critical.

**Q13: "What is mutual authentication?"**
> Both sides prove their identity: device to fog (Auth1 in M1) AND fog to device (Auth2 in M2). This prevents fog impersonation — an attacker can't set up a fake fog node.

**Q14: "How does the replay attack defense work?"**
> The fog checks |current_time - T1| < 120 seconds. If an attacker replays an old message 5 minutes later, the timestamp difference is 300s, which exceeds 120s → rejected. The fog uses its own real clock, not the simulation time.

**Q15: "What is RBAC?"**
> Role-Based Access Control. Instead of per-user permissions, we assign roles (Admin, Resident, Guest, Device) and each role has a fixed set of allowed operations. 4 roles × 11 operations in our permission matrix.

## MATLAB & Implementation

**Q16: "Why MATLAB?"**
> MATLAB excels at matrix operations, rapid prototyping, and plotting — ideal for academic simulation. Java interop gives us real SHA-256. MATLAB Online lets us demo without any installation.

**Q17: "How do you generate SHA-256 in MATLAB?"**
> Java interop: `java.security.MessageDigest.getInstance('SHA-256')`. MATLAB runs on the JVM, so we call Java's crypto library directly. The input is converted to bytes, hashed, and output as hex.

**Q18: "How many files is the project?"**
> 26 MATLAB files across 7 modules: utils, init, network, auth, access, eval, and viz. Plus 4 root-level entry scripts. About 1,500 lines total.

---

# REPORT STATUS

Your `report/midterm_report.txt` is **already complete** and covers all required sections:

| Required Section | Status | Location in Report |
|-----------------|--------|-------------------|
| Introduction | ✅ | Section 1 (1.1-1.4) |
| Literature Survey | ✅ | Section 2 (2.1-2.6, 10 references) |
| Implementation | ✅ | Section 3 (3.1-3.8, detailed) |

> The report is 202 lines (~5 pages when formatted). It covers all 6 evaluation criteria with formulas and technical depth. No changes needed.

---

# 60-SECOND ELEVATOR PITCH (if professor says "summarize in 1 minute")

> "We built LAFSH — a fog computing simulation for smart homes in MATLAB. We deploy 500 heterogeneous IoT devices across six types, with proper energy and range differences. Communication uses the first-order radio model. We implemented LEACH-SEP clustering — that's LEACH extended with SEP for heterogeneous networks — so high-energy devices become cluster heads more often, protecting low-energy sensors.
>
> On top of this network layer, we built a 4-phase lightweight authentication protocol using only SHA-256 hashes — 11,000 times more efficient than TLS. We also have RBAC access control and a security analysis that blocks all 6 tested attack scenarios. Everything runs in MATLAB Online and we can demo it right now."
