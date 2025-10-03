extends Node
class_name NEOHelperFunctions

const MU_SUN = 1.32712440018e11  # km^3/s^2, solar GM (not used here, but handy)

# --- Effective diameter ---
static func effective_diameter_km(H_mag: float, albedo: float = -1.0, rng_seed: int = -1) -> float:
	"""
	Compute effective diameter (km) from absolute magnitude H_mag and albedo.
	If albedo missing (< 0), sample a plausible one between 0.05–0.25.
	"""
	var rng = RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	
	var alb = albedo
	if albedo < 0:
		alb = rng.randf_range(0.05, 0.25)
	
	return 1329.0 * pow(10.0, -H_mag / 5.0) / sqrt(alb)


# --- Axis ratios (a/b, c/b) ---
static func sample_axis_ratios(rng_seed: int = -1, lightcurve_amp: float = -1.0) -> Vector2:
	"""
	Estimate axis ratios from lightcurve amplitude (if available),
	otherwise sample from plausible distributions.
	Returns Vector2(a/b, c/b)
	"""
	var rng = RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	
	var ab: float
	if lightcurve_amp >= 0:
		ab = max(1.1, pow(10.0, 0.4 * lightcurve_amp))
	else:
		# Lognormal approximation: generate normal then exp
		var normal_val = rng.randfn(log(1.4), 0.25)
		ab = clamp(exp(normal_val), 1.1, 3.0)
	
	var cb = clamp(rng.randfn(0.8, 0.1), 0.5, 1.0)
	
	return Vector2(ab, cb)


# --- Ellipsoid axes (a, b, c) ---
static func ellipsoid_axes_from_diameter(H_mag: float, albedo: float = -1.0, 
								  lightcurve_amp: float = -1.0, rng_seed: int = -1) -> Vector3:
	"""
	Derive ellipsoid semi-axes (a, b, c) in km.
	Conserve volume from effective diameter sphere.
	Returns Vector3(a, b, c)
	"""
	var D_eff = effective_diameter_km(H_mag, albedo, rng_seed)
	var ratios = sample_axis_ratios(rng_seed, lightcurve_amp)
	var ab = ratios.x
	var cb = ratios.y
	
	var s = (D_eff / 2.0) * pow(1.0 / (ab * cb), 1.0 / 3.0)
	var a_axis = ab * s
	var b_axis = s
	var c_axis = cb * s
	
	return Vector3(a_axis, b_axis, c_axis)


# --- Basic rotations ---
static func Rz(theta: float) -> Basis:
	"""Rotation matrix around Z axis"""
	var c = cos(theta)
	var s = sin(theta)
	return Basis(
		Vector3(c, s, 0),
		Vector3(-s, c, 0),
		Vector3(0, 0, 1)
	)


static func Rx(theta: float) -> Basis:
	"""Rotation matrix around X axis"""
	var c = cos(theta)
	var s = sin(theta)
	return Basis(
		Vector3(1, 0, 0),
		Vector3(0, c, s),
		Vector3(0, -s, c)
	)


# --- Synthetic spin state ---
static func synth_spin_euler_zyx(i_deg: float, raan_deg: float, rng_seed: int = -1,
						  obliq_max_deg: float = 60.0, W0_deg: float = -1.0,
						  t_hours: float = 0.0, spin_period_h: float = -1.0) -> Dictionary:
	"""
	Generate a synthetic spin orientation:
	- Start from orbit plane normal (i, Ω).
	- Apply random obliquity tilt.
	- Apply prime meridian rotation with synthetic spin period.
	Returns dictionary with: roll, pitch, yaw (ZYX Euler) in radians + rotation Basis
	"""
	var rng = RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	
	# Orbit normal in J2000
	var i_rad = deg_to_rad(i_deg)
	var OM_rad = deg_to_rad(raan_deg)
	var n = Rz(OM_rad) * Rx(i_rad) * Vector3(0, 0, 1)
	
	# Random obliquity
	var eps = deg_to_rad(rng.randf_range(0, obliq_max_deg))
	var ref = Vector3(1, 0, 0)
	if abs(ref.dot(n)) > 0.95:
		ref = Vector3(0, 1, 0)
	
	var u = ref - ref.dot(n) * n
	u = u.normalized()
	
	# Tilt orbit normal by obliquity (Rodrigues' rotation formula)
	var K = Basis(
		Vector3(0, u.z, -u.y),
		Vector3(-u.z, 0, u.x),
		Vector3(u.y, -u.x, 0)
	)
	var I = Basis.IDENTITY
	var R_tilt = I + sin(eps) * K + (1 - cos(eps)) * (K * K)
	var k = R_tilt * n  # synthetic spin axis (body z-axis)
	
	# Prime meridian rotation
	var W0 = W0_deg if W0_deg >= 0 else rng.randf_range(0, 360)
	var period = spin_period_h if spin_period_h > 0 else rng.randf_range(4, 10)
	var W_rad = deg_to_rad(fmod(W0 + 360.0 * (t_hours / period), 360.0))
	
	# Build body axes
	var e = ref - ref.dot(k) * k
	if e.length() < 1e-8:
		var ref2 = Vector3(0, 1, 0)
		e = ref2 - ref2.dot(k) * k
	e = e.normalized()
	
	var Kk = Basis(
		Vector3(0, k.z, -k.y),
		Vector3(-k.z, 0, k.x),
		Vector3(k.y, -k.x, 0)
	)
	var R_W = I + sin(W_rad) * Kk + (1 - cos(W_rad)) * (Kk * Kk)
	var x_body = R_W * e
	var z_body = k
	var y_body = z_body.cross(x_body)
	
	# Rotation matrix body → J2000
	var R = Basis(x_body, y_body, z_body)
	
	# Euler ZYX (yaw Z, pitch Y, roll X)
	var yaw = atan2(R[0].y, R[0].x)
	var pitch = asin(-R[0].z)
	var roll = atan2(R[1].z, R[2].z)
	
	return {
		"roll": roll,
		"pitch": pitch,
		"yaw": yaw,
		"rotation_matrix": R
	}
