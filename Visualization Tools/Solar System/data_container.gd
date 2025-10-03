extends Node
class_name SolarDataContainer

const DEIMOSBUMP = preload("uid://d0481pnjm4w0c")
const EARTHBUMP_1K = preload("uid://cg1ie7yjrp83i")
const JUPITERMAP = preload("uid://b51aulpjl86xk")
const MARSBUMP_1K = preload("uid://dbeeheychtdco")
const MARSMAP_1K = preload("uid://dls8wux1mt4ss")
const MERCURYBUMP = preload("uid://drfobg88qs6mn")
const MERCURYMAP = preload("uid://ig7xk2th3oqv")
const MOONMAP_4K = preload("uid://c1ta5gb8858xl")
const NEPTUNEMAP = preload("uid://bltg6q0nm502u")
const PHOBOSBUMP = preload("uid://belahu0e4wcho")
const PLUTOBUMP_1K = preload("uid://dyropivhcdxr5")
const PLUTOMAP_1K = preload("uid://t6tudyat40he")
const SATURNMAP = preload("uid://cp4hu0jyg6efx")
const SATURNRINGCOLOR = preload("uid://b3bw4m4y6ndh")
const SUNMAP = preload("uid://884ysnnfkd0h")
const URANUSMAP = preload("uid://cl0o57m7rh01k")
const URANUSRINGCOLOUR = preload("uid://c0l560l6ifail")
const VENUSBUMP = preload("uid://dijeu6l11elm1")
const VENUSMAP = preload("uid://kbui6ri7y6e0")
const EARTH_MAP = preload("uid://ccyunuusom6yf")

# Real planetary data with accurate orbital parameters
var celestial_bodies = {
	"Sun": {
		"distance": 0.0,
		"size": 1.0,
		"rotation_period": 609.12,  # hours (25.4 days at equator)
		"orbital_period": 0.0,
		"eccentricity": 0.0,
		"inclination": 0.0,
		"axial_tilt": 7.25,  # degrees relative to ecliptic
		"ascending_node": 0.0,
		"arg_periapsis": 0.0,
		"color_map": SUNMAP,
		"bump_map": null,
		"emissive": true
	},
	"Mercury": {
		"distance": 0.39,  # AU
		"size": 0.038,
		"rotation_period": 1407.6,  # hours (58.6 days)
		"orbital_period": 88.0,  # days
		"eccentricity": 0.2056,  # Most eccentric of major planets
		"inclination": 7.005,  # degrees
		"axial_tilt": 0.034,  # Nearly no tilt
		"ascending_node": 48.331,
		"arg_periapsis": 29.124,
		"color_map": MERCURYMAP,
		"bump_map": MERCURYBUMP,
		"emissive": false
	},
	"Venus": {
		"distance": 0.72,
		"size": 0.095,
		"rotation_period": -5832.5,  # Retrograde rotation (243 days)
		"orbital_period": 224.7,
		"eccentricity": 0.0067,  # Nearly circular
		"inclination": 3.395,
		"axial_tilt": 177.4,  # Nearly upside down
		"ascending_node": 76.680,
		"arg_periapsis": 54.884,
		"color_map": VENUSMAP,
		"bump_map": VENUSBUMP,
		"emissive": false
	},
	"Earth": {
		"distance": 1.0,
		"size": 0.1,
		"rotation_period": 24.0,  # hours
		"orbital_period": 365.25,  # days
		"eccentricity": 0.0167,
		"inclination": 0.0,  # Reference plane (ecliptic)
		"axial_tilt": 23.44,  # Causes seasons
		"ascending_node": 0.0,
		"arg_periapsis": 102.937,
		"color_map": EARTH_MAP,
		"bump_map": EARTHBUMP_1K,
		"emissive": false
	},
	"Moon": {
		"distance": 1.0026,
		"size": 0.027,
		"rotation_period": 655.7,  # hours (27.3 days - tidally locked)
		"orbital_period": 27.3,  # days
		"eccentricity": 0.0549,
		"inclination": 5.145,  # Relative to ecliptic
		"axial_tilt": 6.68,
		"ascending_node": 0.0,
		"arg_periapsis": 0.0,
		"color_map": MOONMAP_4K,
		"bump_map": null,
		"emissive": false,
		"parent": "Earth"
	},
	"Mars": {
		"distance": 1.52,
		"size": 0.053,
		"rotation_period": 24.6,  # hours
		"orbital_period": 687.0,  # days
		"eccentricity": 0.0934,  # Fairly eccentric
		"inclination": 1.850,
		"axial_tilt": 25.19,  # Similar to Earth
		"ascending_node": 49.558,
		"arg_periapsis": 286.502,
		"color_map": MARSMAP_1K,
		"bump_map": MARSBUMP_1K,
		"emissive": false
	},
	"Phobos": {
		"distance": 1.5201,
		"size": 0.0022,
		"rotation_period": 7.65,  # hours (tidally locked)
		"orbital_period": 0.32,  # days
		"eccentricity": 0.0151,
		"inclination": 1.093,
		"axial_tilt": 0.0,
		"ascending_node": 0.0,
		"arg_periapsis": 0.0,
		"color_map": null,
		"bump_map": PHOBOSBUMP,
		"emissive": false,
		"parent": "Mars"
	},
	"Deimos": {
		"distance": 1.5203,
		"size": 0.0012,
		"rotation_period": 30.3,  # hours (tidally locked)
		"orbital_period": 1.26,  # days
		"eccentricity": 0.00033,  # Nearly circular
		"inclination": 0.93,
		"axial_tilt": 0.0,
		"ascending_node": 0.0,
		"arg_periapsis": 0.0,
		"color_map": null,
		"bump_map": DEIMOSBUMP,
		"emissive": false,
		"parent": "Mars"
	},
	"Jupiter": {
		"distance": 5.2,
		"size": 0.5,
		"rotation_period": 9.9,  # hours (fastest rotating planet)
		"orbital_period": 4331.0,  # days (11.86 years)
		"eccentricity": 0.0489,
		"inclination": 1.303,
		"axial_tilt": 3.13,  # Small tilt
		"ascending_node": 100.464,
		"arg_periapsis": 273.867,
		"color_map": JUPITERMAP,
		"bump_map": null,
		"emissive": false
	},
	"Saturn": {
		"distance": 9.54,
		"size": 0.42,
		"rotation_period": 10.7,  # hours
		"orbital_period": 10747.0,  # days (29.4 years)
		"eccentricity": 0.0565,
		"inclination": 2.485,
		"axial_tilt": 26.73,  # Causes ring visibility changes
		"ascending_node": 113.665,
		"arg_periapsis": 339.392,
		"color_map": SATURNMAP,
		"bump_map": null,
		"emissive": false,
		"has_ring": true,
		"ring_texture": SATURNRINGCOLOR
	},
	"Uranus": {
		"distance": 19.2,
		"size": 0.18,
		"rotation_period": -17.2,  # hours (retrograde)
		"orbital_period": 30589.0,  # days (83.7 years)
		"eccentricity": 0.0457,
		"inclination": 0.773,
		"axial_tilt": 97.77,  # Rotates on its side!
		"ascending_node": 74.006,
		"arg_periapsis": 96.998,
		"color_map": URANUSMAP,
		"bump_map": null,
		"emissive": false,
		"has_ring": true,
		"ring_texture": URANUSRINGCOLOUR
	},
	"Neptune": {
		"distance": 30.0,
		"size": 0.17,
		"rotation_period": 16.1,  # hours
		"orbital_period": 59800.0,  # days (163.7 years)
		"eccentricity": 0.0113,
		"inclination": 1.770,
		"axial_tilt": 28.32,
		"ascending_node": 131.784,
		"arg_periapsis": 276.336,
		"color_map": NEPTUNEMAP,
		"bump_map": null,
		"emissive": false
	},
	"Pluto": {
		"distance": 39.5,
		"size": 0.018,
		"rotation_period": -153.3,  # hours (retrograde, 6.4 days)
		"orbital_period": 90560.0,  # days (248 years)
		"eccentricity": 0.2488,  # Very eccentric - crosses Neptune's orbit
		"inclination": 17.16,  # Highly inclined
		"axial_tilt": 122.53,
		"ascending_node": 110.299,
		"arg_periapsis": 113.834,
		"color_map": PLUTOMAP_1K,
		"bump_map": PLUTOBUMP_1K,
		"emissive": false
	}
}
