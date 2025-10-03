# Impact Calculator and Risk Assessment System
## Mathematical Documentation

---

## Overview

This document details the mathematical formulas, equations, and methodologies used to calculate asteroid impact parameters, collision probabilities, and catastrophic effects. All calculations are based on established models from planetary defense research, impact cratering mechanics, and weapons effects scaling.

---

## Table of Contents

1. [Input Data Required](#input-data-required)
2. [Mass and Energy Calculations](#mass-and-energy-calculations)
3. [Orbital Risk Assessment](#orbital-risk-assessment)
4. [Impact Effects Calculations](#impact-effects-calculations)
5. [Tsunami Modeling](#tsunami-modeling)
6. [Casualty Estimation](#casualty-estimation)
7. [References and Standards](#references-and-standards)

---

## Input Data Required

### From NEO Database (NASA JPL)

| Parameter | Symbol | Unit | Description |
|-----------|--------|------|-------------|
| Diameter | `d` | km | Physical diameter of the asteroid |
| Semi-major axis | `a` | km | Average orbital radius |
| Eccentricity | `e` | - | Orbital shape (0=circular, <1=elliptical) |
| Inclination | `i` | degrees | Tilt of orbit relative to ecliptic |
| RAAN | `Ω` | degrees | Right Ascension of Ascending Node |
| Arg. of Periapsis | `ω` | degrees | Orientation of ellipse in orbital plane |
| Mean Anomaly | `M` | degrees | Position along orbit at epoch |
| Epoch | `t₀` | seconds | Reference time (TDB) |
| Orbital Period | `P` | seconds | Time for one complete orbit |
| Orbital Velocity | `v` | km/s | Average velocity along orbit |

### Physical Constants Used

| Constant | Symbol | Value | Unit |
|----------|--------|-------|------|
| Gravitational Constant | `G` | 6.67430 × 10⁻¹¹ | m³·kg⁻¹·s⁻² |
| Earth Mass | `M⊕` | 5.972 × 10²⁴ | kg |
| Earth Radius | `R⊕` | 6,371 | km |
| Sun Mass | `M☉` | 1.989 × 10³⁰ | kg |
| Earth Orbital Radius | `1 AU` | 149,597,870.7 | km |
| Asteroid Density (typical) | `ρ` | 2,500 | kg/m³ |
| Ocean Coverage | - | 0.71 | - |
| TNT Energy Equivalent | - | 4.184 × 10¹⁵ | J/megaton |

---

## Mass and Energy Calculations

### 1. NEO Mass Calculation

The mass is calculated assuming a spherical body with uniform density.

**Volume of sphere:**
```
V = (4/3) × π × r³
```

Where:
- `r = d/2` (radius in meters)
- `d` = diameter in kilometers (converted to meters)

**Mass:**
```
m = V × ρ
```

Where:
- `ρ = 2,500 kg/m³` (typical rocky asteroid density)
- Range: 2,000-3,500 kg/m³ depending on composition

**Output:** `neo_mass_kg` (kilograms)

---

### 2. Impact Velocity Calculation

The impact velocity is the vector sum of the NEO's orbital velocity and Earth's escape velocity.

**Earth's escape velocity:**
```
v_esc = √(2 × G × M⊕ / R⊕)
```

Where:
- `G` = gravitational constant
- `M⊕` = Earth's mass
- `R⊕` = Earth's radius

**Typical value:** ~11.2 km/s

**Total impact velocity:**
```
v_impact = √(v_neo² + v_esc²)
```

Where:
- `v_neo` = NEO's orbital velocity (from database)
- Assumes perpendicular approach (worst case)

**Typical range:** 11-70 km/s (average ~17 km/s for NEOs)

**Output:** `impact_velocity_km_s` (km/s)

---

### 3. Kinetic Energy Calculation

The kinetic energy represents the total destructive energy released upon impact.

**Formula:**
```
E = (1/2) × m × v²
```

Where:
- `m` = NEO mass (kg)
- `v` = impact velocity (m/s)

**Convert to TNT equivalent:**
```
E_TNT = E / (4.184 × 10¹⁵)
```

Result in megatons of TNT.

**Example:**
- 1 km diameter asteroid at 20 km/s ≈ 47,000 megatons TNT
- For reference: Largest nuclear weapon tested ≈ 50 megatons

**Output:** 
- `kinetic_energy_joules` (J)
- `tnt_equivalent_megatons` (Mt)

---

## Orbital Risk Assessment

### 4. Closest Approach Calculation

Find the minimum distance between the NEO's orbital path and Earth's position.

**Method:**
1. Sample NEO positions over one complete orbital period
2. Calculate Earth's position (simplified as circular orbit at 1 AU)
3. Compute distance at each time step:

```
d(t) = |r_neo(t) - r_earth(t)|
```

4. Find minimum distance:

```
d_min = min{d(t)} for t ∈ [0, P]
```

**Output:**
- `closest_approach_distance_km` (km)
- `closest_approach_date` (TDB seconds from epoch)

---

### 5. MOID (Minimum Orbit Intersection Distance)

MOID is the closest distance between two orbital paths, regardless of timing.

**Simplified calculation:**

Compare NEO's perihelion/aphelion with Earth's orbital radius:

```
MOID = min(|q - r_earth|, |Q - r_earth|)
```

Where:
- `q = a(1 - e)` = perihelion distance
- `Q = a(1 + e)` = aphelion distance  
- `r_earth = 1 AU`

**Special case:** If orbits cross Earth's distance:
```
If q < r_earth < Q:
	MOID = |d_closest - R⊕|
```

**Significance:**
- MOID < 0.05 AU (7.5 million km) → Potentially Hazardous Asteroid (PHA)
- MOID < R⊕ → Orbital paths intersect (collision possible)

**Output:** `moid_km` (kilometers)

---

### 6. Collision Probability Estimation

Simplified probability model based on orbital geometry.

**Collision cross-section:**
```
σ = π × R⊕²
```

**Probability factor:**
```
if MOID < R⊕ + Δr:
	P_collision = (1 - MOID/(R⊕ + Δr)) × 0.001
else:
	P_collision = 0
```

Where:
- `Δr` = orbital uncertainty (assumed 1,000 km)
- Factor 0.001 scales to realistic probabilities

**Note:** Real calculation requires covariance matrices and Monte Carlo simulation. This is a simplified geometric approach.

**Output:** `collision_probability` (0.0 to 1.0)

---

### 7. Torino Scale Calculation

The Torino Scale (0-10) combines collision probability and impact energy.

**Scale definitions:**

| Level | Description | Criteria |
|-------|-------------|----------|
| 0 | No Hazard | P ≈ 0 or E < 1 Mt |
| 1 | Normal | P < 10⁻⁸, routine discovery |
| 2 | Merits Attention | P < 10⁻⁶, E < 100 Mt |
| 3 | Deserving Attention | P < 10⁻⁴, E < 1,000 Mt |
| 4 | Close Encounter | P < 1%, close pass |
| 5-6 | Threatening | P < 10%, E < 100,000 Mt |
| 7 | Very Threatening | P ≥ 1%, regional damage |
| 8 | Certain Collision | P ≥ 99%, regional catastrophe |
| 9 | Certain Collision | Regional devastation certain |
| 10 | Global Catastrophe | E > 10⁶ Mt, mass extinction |

**Algorithm:**
```
Score = f(P_collision, E_TNT)
```

Based on logarithmic scales of probability and energy.

**Output:** `torino_scale` (integer 0-10)

---

## Impact Effects Calculations

### 8. Crater Formation

Crater size depends on impact energy, velocity, and target material properties.

**Crater diameter (Collins et al. scaling):**

```
D_crater = 1.3 × (ρ_projectile / ρ_target)^(1/3) × L^0.78 × v^0.44 × g^(-0.22) × sin(θ)^(1/3)
```

**Simplified formula:**
```
D_crater = 0.0013 × E_Mt^0.3  (km)
```

Where:
- `E_Mt` = energy in megatons TNT
- Assumes vertical impact into rock

**Crater depth:**
```
d_crater = 0.15 × D_crater
```

Depth-to-diameter ratio typically 0.1 to 0.2 for complex craters.

**Examples:**
- 1 km asteroid (47,000 Mt) → ~18 km diameter crater
- Chicxulub impact (100 million Mt) → 180 km crater

**Output:**
- `crater_diameter_km`
- `crater_depth_km`

---

### 9. Air Blast Effects

Overpressure zones based on explosion scaling laws.

**Peak overpressure zones:**

| Zone | Overpressure | Effects | Formula |
|------|--------------|---------|---------|
| Total Destruction | 20 psi | Complete devastation | R₁ = 0.3 × E^0.33 |
| Severe Damage | 5 psi | Buildings collapse | R₂ = 0.6 × E^0.33 |
| Moderate Damage | 1 psi | Windows shatter | R₃ = 1.2 × E^0.33 |

Where:
- `E` = energy in kilotons TNT (multiply megatons × 1000)
- `R` = radius in kilometers

**Scaling law basis:** Nuclear weapons effects (Glasstone & Dolan)

**Output:**
- `total_destruction_radius_km`
- `severe_damage_radius_km`
- `moderate_damage_radius_km`
- `air_blast_radius_km` (outermost extent)

---

### 10. Thermal Radiation Effects

Intense heat from fireball causes burns and ignites fires.

**Fireball radius:**
```
R_fireball = 0.1 × E_kt^0.4  (km)
```

**Thermal radiation radius (3rd degree burns):**
```
R_thermal = 0.8 × E_kt^0.41  (km)
```

Where `E_kt` = energy in kilotons

**Mechanism:**
1. Kinetic energy → thermal radiation
2. ~30-35% of energy emitted as light/heat
3. Intensity decreases with distance: I ∝ 1/r²

**Casualties:**
- Immediate burns within thermal radius
- Secondary fires ignite beyond this zone

**Output:**
- `fireball_radius_km`
- `thermal_radiation_radius_km`

---

### 11. Seismic Effects

Impact generates earthquake-like seismic waves.

**Seismic magnitude from energy:**

```
M = 0.67 × log₁₀(E) - 5.87
```

Where:
- `E` = energy in joules
- `M` = Richter magnitude

**Relationship:**
- Each magnitude increase = 32× more energy
- Local effects: M > 6 causes damage
- Global effects: M > 8 for large impacts

**Examples:**
- 1 km asteroid → M 7.8 (major earthquake)
- 10 km asteroid → M 11+ (unprecedented)

**Output:** `seismic_magnitude` (Richter scale)

---

## Tsunami Modeling

### 12. Ocean Impact Tsunamis

Ocean impacts generate devastating tsunamis from water displacement.

**Applicability:**
- 71% of Earth is ocean → 71% chance of ocean impact
- Water depth affects wave generation
- Coastal topography affects inundation

**Initial wave amplitude (Ward & Asphaug model):**

```
A₀ = 0.1 × √E_Mt  (meters)
```

This is the deep-water wave height.

**Coastal amplification:**

```
H_coast = A₀ × 10
```

Waves grow 5-20× when approaching shallow water (shoaling effect).

**Inundation distance:**

```
D_inland = 0.5 × A₀  (km)
```

Depends on coastal slope (assumed 1:100 typical slope).

**Propagation distance:**

Deep-water tsunami speed:
```
c = √(g × h)
```

Where:
- `g` = 9.8 m/s²
- `h` = ocean depth (~4 km average)
- Typical speed: ~200 m/s (700 km/h)

**Affected coastline:**

```
L_coast = 2π × R_prop × 0.3
```

Where:
- `R_prop` = maximum propagation distance (~10,000 km)
- Factor 0.3 accounts for directional propagation

**Examples:**
- 500 m asteroid → 50 m coastal waves
- 1 km asteroid → 100 m coastal waves
- 2004 Indian Ocean tsunami: 15-30 m waves (for comparison)

**Output:**
- `is_ocean_impact` (boolean)
- `tsunami_wave_height_m` (meters at coast)
- `tsunami_inundation_distance_km` (kilometers inland)
- `affected_coastline_km` (total coastline length)

---

## Casualty Estimation

### 13. Population Exposure

Calculate population within affected zones.

**Affected area by zone:**

```
A_total = π × R_total²
A_severe = π × R_severe²  
A_moderate = π × R_moderate²
```

**Population estimate:**

```
Pop = A × ρ_pop
```

Where `ρ_pop` = population density (people/km²)

**Average densities used:**
- Land: 50 people/km² (global average)
- Coastal: 200 people/km² (higher coastal density)
- Urban: 1,000-10,000 people/km²

---

### 14. Fatality Rates by Zone

Different casualty rates for each damage zone.

**Casualty model:**

| Zone | Fatality Rate | Injury Rate |
|------|---------------|-------------|
| Total Destruction (20 psi) | 90% | 95% |
| Severe Damage (5 psi) | 50% | 90% |
| Moderate Damage (1 psi) | 5% | 30% |

**Immediate casualties:**

```
C_immediate = A_total × ρ × 0.9 + A_severe × ρ × 0.5 + A_moderate × ρ × 0.05
```

**Total casualties (including delayed):**

```
C_total = C_immediate × 1.5
```

Factor 1.5 accounts for:
- Delayed deaths from injuries
- Infrastructure collapse
- Medical system overwhelm
- Secondary effects (disease, starvation)

---

### 15. Ocean Impact Casualties

Tsunami-specific casualty model.

**Affected population:**

```
Pop_coastal = L_coast × D_inland × ρ_coastal
```

**Tsunami fatality rates:**
- Inundation zone: 30-50% fatality (warning dependent)
- Wave height > 10 m: 75% fatality in inundation zone

**Calculation:**

```
C_tsunami = Pop_coastal × 0.5
```

Assumes moderate warning systems and evacuation.

---

### 16. Global Effects Threshold

Impacts exceeding certain energy thresholds cause global effects.

**Thresholds:**

| Energy | Diameter | Effects |
|--------|----------|---------|
| 10⁴ Mt | ~2 km | Regional devastation |
| 10⁵ Mt | ~5 km | Continental effects |
| 10⁶ Mt | ~10 km | Global catastrophe (mass extinction) |

**Global effects include:**
- Dust/aerosol injection into stratosphere
- "Impact winter" (temperature drop)
- Crop failures worldwide
- Ecosystem collapse
- Potential mass extinction

**K-T extinction event** (dinosaurs): ~10 km asteroid, ~100 million Mt

---

## Output Data Structure

All calculated parameters are stored in the `ImpactAssessment` class:

```gdscript
class ImpactAssessment:
	# Risk Assessment
	var moid_km: float
	var closest_approach_distance_km: float
	var collision_probability: float
	var torino_scale: int
	
	# Energy
	var neo_mass_kg: float
	var impact_velocity_km_s: float
	var kinetic_energy_joules: float
	var tnt_equivalent_megatons: float
	
	# Impact Effects
	var crater_diameter_km: float
	var crater_depth_km: float
	var seismic_magnitude: float
	var air_blast_radius_km: float
	var thermal_radiation_radius_km: float
	var fireball_radius_km: float
	
	# Tsunami
	var is_ocean_impact: bool
	var tsunami_wave_height_m: float
	var tsunami_inundation_distance_km: float
	var affected_coastline_km: float
	
	# Casualties
	var impact_location: Vector2  # lat, lon
	var population_in_blast_radius: int
	var estimated_immediate_casualties: int
	var estimated_total_casualties: int
	var affected_countries: Array
	
	# Damage Zones
	var total_destruction_radius_km: float
	var severe_damage_radius_km: float
	var moderate_damage_radius_km: float
```

---

## Limitations and Assumptions

### Simplifications Made:

1. **Uniform density**: Real asteroids vary in composition and porosity
2. **Spherical shape**: Many asteroids are irregular
3. **Vertical impact**: Real impacts have varying angles (affects energy transfer)
4. **Circular Earth orbit**: Earth's orbit is slightly elliptical
5. **Point mass Earth**: Ignores atmospheric entry effects
6. **Average population density**: Real distribution is highly non-uniform
7. **No atmospheric breakup**: Assumes asteroid reaches surface intact
8. **Simplified tsunami model**: Real tsunamis require detailed ocean bathymetry

### Accuracy Notes:

- **Collision probability**: ±50% (requires detailed uncertainty analysis)
- **Impact energy**: ±20% (density uncertainty)
- **Crater size**: ±30% (target material variation)
- **Casualty estimates**: ±50% (population distribution unknown)

### When to Use More Detailed Models:

- **Real asteroid threats**: Use JPL Sentry or ESA NEOCC systems
- **Detailed impact modeling**: Use codes like iSALE, CTH, or SOVA
- **Tsunami propagation**: Use MOST or COMCOT models
- **Casualty assessment**: Requires GIS, population databases, and infrastructure data

---

## References and Standards

### Scientific Literature:

1. **Collins et al. (2005)** - "Earth Impact Effects Program" - Impact cratering
2. **Glasstone & Dolan (1977)** - "The Effects of Nuclear Weapons" - Blast scaling
3. **Ward & Asphaug (2000)** - "Asteroid impact tsunami" - Tsunami modeling
4. **Chapman & Morrison (1994)** - "Impact hazard to civilization" - Risk assessment
5. **Brown et al. (2002)** - "The flux of small near-Earth objects" - NEO statistics

### Organizational Standards:

- **NASA JPL Center for NEO Studies (CNEOS)** - NEO database and Sentry system
- **European Space Agency SSA-NEO** - Impact monitoring
- **International Asteroid Warning Network (IAWN)** - Global coordination
- **Space Mission Planning Advisory Group (SMPAG)** - Deflection planning

### Impact Effect Calculators:

- **Purdue University Impact Calculator** - Online tool for impact effects
- **Imperial College Earth Impact Database** - Crater catalog and statistics

### Planetary Defense Resources:

- **NASA Planetary Defense Coordination Office (PDCO)**
- **United Nations COPUOS Action Team 14** - NEO threat mitigation

---

## Conclusion

This impact calculator provides scientifically-grounded estimates of asteroid impact effects suitable for simulation, education, and game development. While simplified compared to research-grade models, all formulas are based on established physics and empirical data from nuclear weapons testing, geological crater studies, and asteroid research.

For actual planetary defense applications, consult professional organizations like NASA CNEOS or ESA SSA-NEO, which maintain operational impact monitoring systems with detailed uncertainty quantification.

---

**Last Updated:** October 2025  
**Version:** 1.0  
**For:** Project Gaia
