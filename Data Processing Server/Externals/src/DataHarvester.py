#!/usr/bin/env python3
"""
Build an offline NEO database from NASA NeoWS 'browse' endpoint.
- Requires a NASA API key at internals/api_key.py -> NASA_API_KEY = "..."
- Produces neodb.json with real orbital + physical parameters for 3D rendering.

Fields mapped from NeoWs:
  orbital_data: a (AU), eccentricity, inclination (deg), ascending_node_longitude (Ω, deg),
                perihelion_argument (ω, deg), mean_anomaly (M, deg), epoch_osculation (JD)
  estimated_diameter.kilometers (min/max) -> diameter_km (avg)
  absolute_magnitude_h -> H_mag
  is_potentially_hazardous_asteroid -> pha_flag
"""

import json, math, time, argparse
import requests, certifi

from internals import api_key  # <-- your module with key

NEOWS_BROWSE = "https://api.nasa.gov/neo/rest/v1/neo/browse"
AU_KM = 149_597_870.7

def get_page(page: int, size: int):
    r = requests.get(
        NEOWS_BROWSE,
        params={"page": page, "size": size, "api_key": api_key},
        timeout=30,
        verify=certifi.where(),
    )
    r.raise_for_status()
    return r.json()

def avg_diameter_km(neo):
    try:
        km = neo["estimated_diameter"]["kilometers"]
        return 0.5 * (float(km["estimated_diameter_min"]) + float(km["estimated_diameter_max"]))
    except Exception:
        return None

def to_game_record(neo):
    od = neo.get("orbital_data", {}) or {}

    def fnum(val):
        try: return float(val)
        except: return None

    a_au   = fnum(od.get("semi_major_axis") or od.get("a") or od.get("orbit_determination_date"))  # some libs differ
    if a_au is None:
        a_au = fnum(od.get("a"))
    e      = fnum(od.get("eccentricity") or od.get("e"))
    inc    = fnum(od.get("inclination") or od.get("i"))
    raan   = fnum(od.get("ascending_node_longitude") or od.get("om"))
    argp   = fnum(od.get("perihelion_argument") or od.get("w"))
    M      = fnum(od.get("mean_anomaly") or od.get("ma"))
    epoch  = fnum(od.get("epoch_osculation") or od.get("epoch"))

    # must have basic elements to render an orbit
    if None in (a_au, e, inc, raan, argp, M, epoch):
        return None

    H      = fnum(neo.get("absolute_magnitude_h"))
    D_km   = avg_diameter_km(neo)
    albedo = fnum(od.get("albedo"))  # rarely present in NeoWs; may be None

    return {
        "designation": neo.get("name") or neo.get("neo_reference_id"),
        "neo_reference_id": neo.get("neo_reference_id"),
        "epoch_tdb": epoch,                       # NeoWs gives JD (osculation) — good enough for sim epoch
        "a_km": a_au * AU_KM,
        "e": e,
        "i_deg": inc,
        "raan_deg": raan,
        "argp_deg": argp,
        "M_deg": M,
        "H_mag": H,
        "diameter_km": D_km,
        "albedo": albedo,
        "pha_flag": bool(neo.get("is_potentially_hazardous_asteroid")),
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=150, help="How many NEOs to collect (approx)")
    ap.add_argument("--outfile", default="neodb.json")
    ap.add_argument("--page_size", type=int, default=50, help="NeoWs page size (max ~50)")
    args = ap.parse_args()

    collected = []
    page = 0
    while len(collected) < args.count:
        data = get_page(page, args.page_size)
        neos = data.get("near_earth_objects", []) or []
        for neo in neos:
            rec = to_game_record(neo)
            if rec:
                collected.append(rec)
                if len(collected) >= args.count:
                    break
        page += 1
        # polite pacing
        time.sleep(0.1)

        # safety: stop if no next page
        if page > (data.get("page", {}).get("total_pages") or 1000):
            break

    db = {
        "source_note": "Real data from NASA NeoWs (api.nasa.gov). Endpoint: /neo/browse",
        "generated_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "count": len(collected),
        "objects": collected,
    }
    with open(args.outfile, "w", encoding="utf-8") as f:
        json.dump(db, f, ensure_ascii=False, indent=2)

    print(f"Wrote {args.outfile} with {len(collected)} NEOs.")

if __name__ == "__main__":
    main()
