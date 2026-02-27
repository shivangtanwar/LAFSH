# LAFSH — Lightweight Authentication for Fog-Based Smart Homes

A MATLAB simulation of a lightweight authentication and access control mechanism for fog-based smart home systems, featuring mutual authentication, TOTP two-factor auth, device fingerprinting, and RBAC — evaluated over LEACH-SEP clustered heterogeneous IoT networks.

> **Course**: CSE4702 — Fog Computing | BTech 3rd Year, Semester 6

---

## Architecture

```
┌──────────────────────────────────────────────┐
│              CLOUD LAYER                     │
│  Master secrets · Global policy · Audit logs │
└──────────────────┬───────────────────────────┘
                   │  ~100ms latency
┌──────────────────┴───────────────────────────┐
│         FOG LAYER  (Home Gateway)            │
│  Device auth · RBAC enforcement · TOTP       │
│  Session mgmt · Cluster head aggregation     │
└──────────────────┬───────────────────────────┘
                   │  ~5ms latency
┌──────────────────┴───────────────────────────┐
│            EDGE / IoT LAYER                  │
│  Light │ Lock │ Camera │ Thermostat │ Sensor │
│        300–1000 heterogeneous nodes          │
└──────────────────────────────────────────────┘
```

## Features

- **Heterogeneous node deployment** — 300–1000 IoT devices across 6 types (lights, thermostats, cameras, locks, motion sensors, smart plugs) with type-specific energy, range, and capability profiles
- **LEACH-SEP clustering** — Energy-aware cluster head election for heterogeneous networks with automatic re-clustering
- **First-order radio energy model** — Realistic TX/RX energy consumption with free-space and multipath propagation
- **4-phase authentication protocol (LAFSH)**
  - Phase 1: Device registration with anchor keys
  - Phase 2: Mutual authentication + session key establishment (~200 bytes, 8 hash ops)
  - Phase 3: TOTP two-factor authentication (RFC 6238 simplified, 30s window)
  - Phase 4: Device fingerprinting for anti-cloning
- **RBAC access control** — 4 roles (Admin, Resident, Guest, Device) × 11 operations with time-window restrictions and full audit logging
- **Security analysis** — Automated testing against 6 attack scenarios (replay, MITM, impersonation, cloning, TOTP brute-force, privilege escalation)
- **Performance evaluation** — Latency, communication overhead, energy consumption, and security comparison with baseline schemes

## Quick Start

> Requires [MATLAB Online](https://matlab.mathworks.com) or MATLAB R2020b+. No additional toolboxes needed.

1. Clone the repository
   ```
   git clone https://github.com/shivangtanwar/LAFSH.git
   cd LAFSH
   ```
2. Open `main.m` in MATLAB and run it
3. Select an option from the menu:
   ```
   1. Run Interactive Demo        (full pipeline: deploy → cluster → auth → RBAC → attacks)
   2. Run Performance Evaluation  (generates all plots to figures/)
   3. Run Security Analysis       (6 attack scenarios → all blocked)
   4. Display RBAC Permission Matrix
   5. Quick Test                  (300 nodes → cluster → visualize)
   ```

## Project Structure

```
├── main.m                          # Entry point
├── run_demo.m                      # Full narrative demonstration
├── run_evaluation.m                # Performance evaluation suite
├── run_security_analysis.m         # Attack scenario testing
│
├── src/
│   ├── utils/                      # Crypto primitives
│   │   ├── sha256_hash.m           #   SHA-256 via Java MessageDigest
│   │   ├── xor_hex.m               #   Bitwise XOR on hex strings
│   │   ├── generate_nonce.m        #   Random nonce generation
│   │   ├── get_timestamp.m         #   Unix timestamp
│   │   ├── totp_generate.m         #   TOTP code generation
│   │   └── totp_verify.m           #   TOTP verification (±30s grace)
│   │
│   ├── init/                       # System initialization
│   │   ├── init_cloud.m            #   Cloud server setup
│   │   ├── init_fog_node.m         #   Fog node setup
│   │   └── init_rbac.m             #   RBAC policy matrix
│   │
│   ├── network/                    # Network simulation
│   │   ├── deploy_nodes.m          #   Heterogeneous node deployment
│   │   ├── communicate.m           #   First-order radio energy model
│   │   ├── leach_sep_clustering.m  #   LEACH-SEP cluster formation
│   │   └── simulate_communication_round.m
│   │
│   ├── auth/                       # Authentication protocol
│   │   ├── device_register.m       #   Phase 1: Registration
│   │   ├── device_login.m          #   Phase 2: Mutual auth + session key
│   │   ├── totp_auth.m             #   Phase 3: TOTP 2FA
│   │   ├── verify_session.m        #   Session validation
│   │   └── logout_device.m         #   Session teardown
│   │
│   ├── access/                     # Access control
│   │   ├── check_permission.m      #   RBAC policy enforcement
│   │   └── display_audit_log.m     #   Audit log viewer
│   │
│   ├── eval/                       # Performance evaluation
│   │   ├── eval_auth_latency.m     #   Latency vs device count
│   │   ├── eval_communication_overhead.m
│   │   ├── eval_energy_estimation.m
│   │   └── eval_security_comparison.m
│   │
│   └── viz/                        # Visualization
│       ├── plot_deployment.m       #   Node deployment map
│       ├── plot_clusters.m         #   Cluster formation diagram
│       ├── plot_auth_latency.m     #   Latency line chart
│       ├── plot_communication_overhead.m
│       ├── plot_energy_comparison.m
│       ├── plot_security_radar.m   #   Security feature radar chart
│       ├── plot_rbac_heatmap.m     #   Permission matrix heatmap
│       └── plot_network_stats.m    #   Network lifetime panels
│
├── results/                        # Generated .mat files (gitignored)
├── figures/                        # Generated plots (gitignored)
└── report/
    └── midterm_report.txt          # Mid-term project report
```

## RBAC Permission Matrix

| Operation | Admin | Resident | Guest | Device |
|-----------|:-----:|:--------:|:-----:|:------:|
| Lock/Unlock Door | ✓ | ✓ | ✗ | ✗ |
| Camera Live | ✓ | ✓ | ✓* | ✗ |
| Camera Recording | ✓ | ✗ | ✗ | ✗ |
| Set Thermostat | ✓ | ✓ | ✗ | ✗ |
| Read Thermostat | ✓ | ✓ | ✓ | ✓ |
| Control Lights | ✓ | ✓ | ✓ | ✗ |
| Add/Remove Devices | ✓ | ✗ | ✗ | ✗ |
| Firmware Update | ✓ | ✗ | ✗ | ✗ |
| Report Sensor Data | ✓ | ✓ | ✓ | ✓ |

*Guest: only within authorized time windows (09:00–22:00)

## Performance Highlights

| Metric | LAFSH | TLS-Certificate | Improvement |
|--------|------:|----------------:|:-----------:|
| Bytes per auth | ~200 | ~5,000 | **25×** less |
| Energy per auth | 162 µJ | 1,800,000 µJ | **11,000×** less |
| Hash ops per auth | 8 | N/A (RSA) | — |
| Auth latency | <1 ms | ~300 ms | **300×** faster |

## References

1. Bonomi et al., "Fog Computing and Its Role in the Internet of Things," MCC Workshop, 2012
2. Wazid et al., "LAM-CIoT: Lightweight Authentication Mechanism in Cloud-Based IoT," JNCA, 2020
3. Heinzelman et al., "LEACH: Energy-Efficient Communication Protocol for WSN," HICSS, 2000
4. Smaragdakis et al., "SEP: Stable Election Protocol for Heterogeneous WSN," BU Tech Report, 2004
5. RFC 6238 — TOTP: Time-Based One-Time Password Algorithm, 2011

## License

Academic project — not intended for production use.
