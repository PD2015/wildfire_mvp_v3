#!/usr/bin/env python3
"""
Fetch burnt area data from EFFIS WFS and save as JSON bundles.

This script is used by the GitHub Actions workflow to keep burnt area
bundles up-to-date. It fetches GML3 data from EFFIS and converts it
to the JSON format used by the app.

Usage:
    python scripts/fetch_burnt_areas.py

Output:
    - assets/cache/burnt_areas_{year}_uk.json for current and previous year
"""

import json
import os
import re
import sys
from datetime import datetime
from typing import Any
from xml.etree import ElementTree as ET

import requests

# EFFIS WFS endpoint
EFFIS_URL = "https://maps.effis.emergency.copernicus.eu/effis"

# UK bounding box (expanded to include all of UK + Ireland)
UK_BBOX = "-12,49,3,62"

# User agent (required by EFFIS)
USER_AGENT = "WildFire/0.1 (prototype; burnt-area-bundle-update)"

# Namespaces for GML parsing
NAMESPACES = {
    'wfs': 'http://www.opengis.net/wfs/2.0',
    'gml': 'http://www.opengis.net/gml/3.2',
    'ba': 'http://effis.jrc.ec.europa.eu/burnt_area'
}


def fetch_burnt_areas(year: int) -> list[dict[str, Any]]:
    """Fetch burnt area data for a specific year from EFFIS."""
    print(f"🔥 Fetching burnt areas for {year}...")
    
    # Build WFS request
    params = {
        'service': 'WFS',
        'version': '2.0.0',
        'request': 'GetFeature',
        'typeName': f'ba:burnt_area_{year}',
        'outputFormat': 'application/gml+xml; version=3.2',
        'srsName': 'EPSG:4326',
        'bbox': f'{UK_BBOX},EPSG:4326'
    }
    
    headers = {
        'User-Agent': USER_AGENT,
        'Accept': 'application/gml+xml'
    }
    
    try:
        response = requests.get(EFFIS_URL, params=params, headers=headers, timeout=120)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"❌ Failed to fetch data for {year}: {e}")
        return []
    
    # Parse GML response
    features = parse_gml_response(response.text, year)
    print(f"✅ Fetched {len(features)} burnt areas for {year}")
    
    return features


def parse_gml_response(gml_text: str, year: int) -> list[dict[str, Any]]:
    """Parse GML3 response into list of burnt area features."""
    features = []
    
    try:
        root = ET.fromstring(gml_text)
    except ET.ParseError as e:
        print(f"❌ Failed to parse GML: {e}")
        return []
    
    # Find all burnt area members
    for member in root.findall('.//wfs:member', NAMESPACES):
        ba_elem = member.find(f'.//ba:burnt_area_{year}', NAMESPACES)
        if ba_elem is None:
            continue
        
        feature = parse_burnt_area_feature(ba_elem, year)
        if feature:
            features.append(feature)
    
    return features


def parse_burnt_area_feature(elem: ET.Element, year: int) -> dict[str, Any] | None:
    """Parse a single burnt area feature from GML."""
    try:
        # Get feature ID
        fid = elem.get('{http://www.opengis.net/gml/3.2}id', '')
        
        # Parse geometry (polygon coordinates)
        coords_elem = elem.find('.//gml:posList', NAMESPACES)
        if coords_elem is None or not coords_elem.text:
            return None
        
        # Parse coordinate string into list of [lon, lat] pairs
        coords_text = coords_elem.text.strip()
        coords_list = [float(x) for x in coords_text.split()]
        
        # Group into coordinate pairs (GML is lat,lon order)
        boundary_points = []
        for i in range(0, len(coords_list) - 1, 2):
            lat, lon = coords_list[i], coords_list[i + 1]
            boundary_points.append([lon, lat])  # GeoJSON is [lon, lat]
        
        if len(boundary_points) < 3:
            return None
        
        # Parse attributes
        area_ha = float(elem.findtext('.//ba:area_ha', '0', NAMESPACES) or '0')
        fire_date_str = elem.findtext('.//ba:firedate', '', NAMESPACES) or ''
        
        # Parse fire date
        fire_date = None
        if fire_date_str:
            try:
                fire_date = datetime.strptime(fire_date_str[:10], '%Y-%m-%d').isoformat()[:10]
            except ValueError:
                fire_date = fire_date_str[:10] if len(fire_date_str) >= 10 else None
        
        # Calculate centroid
        lons = [p[0] for p in boundary_points]
        lats = [p[1] for p in boundary_points]
        centroid_lon = sum(lons) / len(lons)
        centroid_lat = sum(lats) / len(lats)
        
        return {
            'id': fid,
            'centroid': [centroid_lon, centroid_lat],
            'boundaryPoints': boundary_points,
            'areaHectares': area_ha,
            'fireDate': fire_date,
            'seasonYear': year
        }
    
    except Exception as e:
        print(f"⚠️ Failed to parse feature: {e}")
        return None


def save_bundle(features: list[dict[str, Any]], year: int, output_dir: str) -> str:
    """Save features as JSON bundle."""
    bundle = {
        'year': year,
        'region': 'UK',
        'generatedAt': datetime.utcnow().isoformat() + 'Z',
        'featureCount': len(features),
        'features': features
    }
    
    filename = f'burnt_areas_{year}_uk.json'
    filepath = os.path.join(output_dir, filename)
    
    with open(filepath, 'w') as f:
        json.dump(bundle, f, separators=(',', ':'))
    
    file_size = os.path.getsize(filepath)
    print(f"💾 Saved {filename} ({len(features)} features, {file_size / 1024:.1f} KB)")
    
    return filepath


def main():
    """Main entry point."""
    current_year = datetime.now().year
    previous_year = current_year - 1
    
    print(f"🔄 Updating burnt area bundles for {previous_year} and {current_year}")
    print(f"📅 Generated at: {datetime.utcnow().isoformat()}Z")
    print()
    
    # Determine output directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, '..', 'assets', 'cache')
    os.makedirs(output_dir, exist_ok=True)
    
    success = True
    
    # Fetch and save both years
    for year in [previous_year, current_year]:
        features = fetch_burnt_areas(year)
        
        if features:
            save_bundle(features, year, output_dir)
        else:
            print(f"⚠️ No features fetched for {year}")
            # Don't fail for missing data - the year might not have data yet
    
    # Set GitHub Actions outputs
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
            f.write(f'current_year={current_year}\n')
            f.write(f'previous_year={previous_year}\n')
    
    print()
    print("✅ Bundle update complete!")
    
    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())
