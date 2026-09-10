"""Fetch Mawaqit country mosque lists and build compact offline bundles.

Raw:  https://mawaqit.net/api/2.0/mosque/map/{CODE}  (MBs, 9 fields)
Out:  assets/mosques/{CODE}.json  {"v":1,"list":[[slug,name,city,lat,lng],...]}
Keeps only map-needed fields; coords rounded to 5 decimals (~1m).
"""
import json
import os
import sys
import tempfile
import urllib.request

CODES = ["DZ", "SA", "EG", "MA", "TN", "AE", "FR", "GB", "TR", "DE",
         "CA", "US", "ES", "BE", "IT"]

BASE = r"C:\Users\AHMED\Desktop\Husn-el-Muslim"
OUT_DIR = os.path.join(BASE, "assets", "mosques")
TMP = tempfile.gettempdir()


def fetch(code):
    url = f"https://mawaqit.net/api/2.0/mosque/map/{code}"
    req = urllib.request.Request(
        url, headers={"User-Agent": "Husn-el-Muslim offline-bundle builder"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return r.read()


def compact(raw_bytes):
    data = json.loads(raw_bytes.decode("utf-8"))
    if not isinstance(data, list):
        raise ValueError("unexpected payload")
    out = []
    for m in data:
        if not isinstance(m, dict):
            continue
        slug = (m.get("slug") or "").strip()
        if not slug:
            continue
        try:
            lat = round(float(m.get("lat") or 0), 5)
            lng = round(float(m.get("lng") or 0), 5)
        except (TypeError, ValueError):
            continue
        if lat == 0 and lng == 0:
            continue
        out.append([slug, str(m.get("name") or ""),
                    str(m.get("city") or ""), lat, lng])
    return out


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    manifest = {}
    total = 0
    for code in CODES:
        try:
            raw = fetch(code)
        except Exception as e:  # noqa: BLE001
            print(f"{code}: FETCH FAILED: {e}", flush=True)
            continue
        mosques = compact(raw)
        payload = {"v": 1, "list": mosques}
        text = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
        path = os.path.join(OUT_DIR, f"{code}.json")
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        size = os.path.getsize(path)
        total += size
        manifest[code] = {"count": len(mosques), "bytes": size}
        print(f"{code}: {len(mosques)} mosques, raw={len(raw)}B -> "
              f"bundle={size}B", flush=True)
    with open(os.path.join(OUT_DIR, "manifest.json"), "w",
              encoding="utf-8") as f:
        json.dump(manifest, f, indent=1)
    print(f"TOTAL bundle size: {total}B ({total / 1048576:.2f} MB)")


if __name__ == "__main__":
    sys.exit(main())
