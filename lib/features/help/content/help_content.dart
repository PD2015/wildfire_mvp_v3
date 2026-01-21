/// Help document metadata and content for WildFire app.
///
/// Contains all help and educational content as embedded Dart strings for:
/// - Offline access
/// - Consistent presentation
/// - Easy updates without backend
library;

import 'package:flutter/material.dart';

/// Sections for grouping help documents.
enum HelpSection {
  gettingStarted('Getting Started'),
  wildfireEducation('Wildfire Education'),
  usingTheMap('Using the Map'),
  safetyResponsibility('Safety & Responsibility');

  final String displayName;
  const HelpSection(this.displayName);
}

/// A help document with metadata for display.
class HelpDocument {
  /// Unique identifier for the document (used in routes)
  final String id;

  /// Display title for the document
  final String title;

  /// Short description for list view
  final String description;

  /// Icon to display in the help menu
  final IconData icon;

  /// Section this document belongs to
  final HelpSection section;

  /// Full document content (Markdown formatted)
  final String content;

  const HelpDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.section,
    required this.content,
  });
}

/// Static access to all help documents.
///
/// Usage:
/// ```dart
/// final doc = HelpContent.howToUse;
/// print(doc.title); // "How to Use WildFire"
/// ```
class HelpContent {
  HelpContent._();

  // ─────────────────────────────────────────────────────────────
  // Getting Started Section
  // ─────────────────────────────────────────────────────────────

  /// How to use WildFire app
  static const howToUse = HelpDocument(
    id: 'how-to-use',
    title: 'How to Use the WildFire App',
    description: 'Getting started with the app',
    icon: Icons.menu_book_outlined,
    section: HelpSection.gettingStarted,
    content: _howToUseContent,
  );

  /// When to use this app
  static const whenToUse = HelpDocument(
    id: 'when-to-use',
    title: 'When to Use This App',
    description: 'Best practices for using WildFire',
    icon: Icons.schedule_outlined,
    section: HelpSection.gettingStarted,
    content: _whenToUseContent,
  );

  // ─────────────────────────────────────────────────────────────
  // Wildfire Education Section
  // ─────────────────────────────────────────────────────────────

  /// Understanding wildfire risk
  static const understandingRisk = HelpDocument(
    id: 'understanding-risk',
    title: 'Understanding Wildfire Risk',
    description: 'How wildfire risk is calculated',
    icon: Icons.local_fire_department_outlined,
    section: HelpSection.wildfireEducation,
    content: _understandingRiskContent,
  );

  /// What the risk levels mean
  static const riskLevels = HelpDocument(
    id: 'risk-levels',
    title: 'What the Risk Levels Mean',
    description: 'Understanding fire danger levels',
    icon: Icons.speed_outlined,
    section: HelpSection.wildfireEducation,
    content: _riskLevelsContent,
  );

  /// Weather, fuel, and fire
  static const weatherFuelFire = HelpDocument(
    id: 'weather-fuel-fire',
    title: 'Weather, Fuel, and Fire',
    description: 'How conditions affect fire danger',
    icon: Icons.thermostat_outlined,
    section: HelpSection.wildfireEducation,
    content: _weatherFuelFireContent,
  );

  /// Seasonal guidance
  static const seasonalGuidance = HelpDocument(
    id: 'seasonal-guidance',
    title: 'Seasonal Guidance',
    description: 'Fire risk through the year',
    icon: Icons.calendar_month_outlined,
    section: HelpSection.wildfireEducation,
    content: _seasonalGuidanceContent,
  );

  // ─────────────────────────────────────────────────────────────
  // Using the Map Section
  // ─────────────────────────────────────────────────────────────

  /// What is a hotspot
  static const hotspots = HelpDocument(
    id: 'hotspots',
    title: 'What Is a Hotspot?',
    description: 'Understanding satellite fire detections',
    icon: Icons.location_on_outlined,
    section: HelpSection.usingTheMap,
    content: _hotspotsContent,
  );

  /// What is a burnt area
  static const burntArea = HelpDocument(
    id: 'burnt-area',
    title: 'What Is a Burnt Area?',
    description: 'Understanding burnt area polygons',
    icon: Icons.layers_outlined,
    section: HelpSection.usingTheMap,
    content: _burntAreaContent,
  );

  /// Update frequency and limits
  static const updateFrequency = HelpDocument(
    id: 'update-frequency',
    title: 'How Recent Is the Map Data?',
    description: 'How often data refreshes',
    icon: Icons.update_outlined,
    section: HelpSection.usingTheMap,
    content: _updateFrequencyContent,
  );

  /// Data sources explained
  static const dataSourcesHelp = HelpDocument(
    id: 'data-sources',
    title: 'Data Sources Explained',
    description: 'Where our data comes from',
    icon: Icons.storage_outlined,
    section: HelpSection.usingTheMap,
    content: _dataSourcesHelpContent,
  );

  // ─────────────────────────────────────────────────────────────
  // Safety & Responsibility Section
  // ─────────────────────────────────────────────────────────────

  /// What to do if you see fire
  static const seeFireAction = HelpDocument(
    id: 'see-fire',
    title: 'What to Do if You See Fire',
    description: 'Emergency response guidance',
    icon: Icons.emergency_outlined,
    section: HelpSection.safetyResponsibility,
    content: _seeFireContent,
  );

  /// Important limitations
  static const limitations = HelpDocument(
    id: 'limitations',
    title: 'Important Limitations',
    description: 'What this app can and cannot do',
    icon: Icons.info_outline,
    section: HelpSection.safetyResponsibility,
    content: _limitationsContent,
  );

  /// Emergency guidance
  static const emergencyGuidance = HelpDocument(
    id: 'emergency-guidance',
    title: 'Emergency Guidance',
    description: 'Emergency contacts and resources',
    icon: Icons.phone_outlined,
    section: HelpSection.safetyResponsibility,
    content: _emergencyGuidanceContent,
  );

  // ─────────────────────────────────────────────────────────────
  // About Section (handled separately via AboutHelpScreen)
  // ─────────────────────────────────────────────────────────────

  // Note: About is a special screen, not a document.
  // It's accessed via /help/about and shows app info + dev options.

  /// All help documents grouped by section (excludes About).
  /// This is the single source of truth for the help menu.
  static const List<HelpDocument> all = [
    // Getting Started
    howToUse,
    whenToUse,
    // Wildfire Education
    understandingRisk,
    riskLevels,
    weatherFuelFire,
    seasonalGuidance,
    // Using the Map
    hotspots,
    burntArea,
    updateFrequency,
    dataSourcesHelp,
    // Safety & Responsibility
    seeFireAction,
    limitations,
    emergencyGuidance,
  ];

  /// Get documents for a specific section.
  static List<HelpDocument> forSection(HelpSection section) {
    return all.where((doc) => doc.section == section).toList();
  }

  /// Find a document by its ID. Returns null if not found.
  static HelpDocument? findById(String id) {
    try {
      return all.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All sections in display order.
  static const List<HelpSection> sections = HelpSection.values;
}

// ─────────────────────────────────────────────────────────────
// Content Definitions
// ─────────────────────────────────────────────────────────────

const _howToUseContent = '''
# How to Use the WildFire App

WildFire helps you stay informed about wildfire risk in Scotland. Here's how to get started:

## Home Screen

The main screen shows your current **Fire Weather Index (FWI)** — a measure of how dangerous fire conditions are right now at your location.

- **Location**: Shows your current location or the location you've set
- **Risk Level**: Shows the current fire danger level from Very Low to Extreme
- **FWI Value**: The numerical Fire Weather Index value

## Viewing the Map

Tap the **Map** tab to see:
- Active fire hotspots detected by satellite
- Your current location
- Burnt area polygons (when zoomed in)

Hotspots are updated throughout the day as satellite data becomes available.

## Reporting Fires

If you see a fire, use the **Report** feature to:
1. Share your current location or pick a point on the map
2. Provide details about what you've observed
3. Submit the report for review

**Remember**: This is for awareness only. Always call **999** for emergencies.

## Tips

- Check the app before outdoor activities like hiking or camping
- Pay attention to seasonal fire bans during high-risk periods
- Share information with friends and family in rural areas
''';

const _whenToUseContent = '''
# When to Use This App

WildFire is designed for **awareness and planning**, not emergency response.

## Good Times to Check

### Before Outdoor Activities
- Check fire risk before hiking, camping, or countryside visits
- Plan routes away from high-risk areas during dry periods
- Know the conditions before using BBQs or campfires

### During Fire Season
- Scotland's main fire season is typically February–May and July–September
- Check more frequently during dry, windy weather
- Monitor conditions if you live in rural or moorland areas

### When Planning Land Management
- Muirburn and controlled burning have legal seasons
- Check conditions before any managed burning activities
- Ensure you have appropriate permissions

## When NOT to Rely on This App

### In an Emergency
- **Call 999 immediately** if you see an uncontrolled fire
- Don't wait for app confirmation — report what you see
- Follow instructions from emergency services

### For Official Decisions
- This app is for awareness only
- Official fire bans come from local authorities
- Land management decisions need professional assessment

### When Conditions Change Rapidly
- Weather can change faster than satellite updates
- Local conditions may differ from general forecasts
- Use common sense alongside app information
''';

const _riskLevelsContent = '''
# What the Risk Levels Mean

WildFire uses the Fire Weather Index (FWI) system used by fire services across Europe.

These levels describe **environmental conditions**, not whether a fire is currently burning or permitted.

This information is provided for awareness only and does not replace official guidance or emergency instructions.

---

## Very Low (FWI 0–4.9)
Fires are unlikely to start or spread, **but ignition is still possible**.  
Normal outdoor activities generally carry **lower risk**, but care is still needed with any heat or flame.

---

## Low (FWI 5–11.9)
Fire conditions are marginal.  
Activities involving flames, sparks, or hot equipment carry increased risk.

---

## Moderate (FWI 12–20.9)
Fires can start and spread under certain conditions.  
Activities involving flames, sparks, or hot equipment should be approached with caution.

---

## High (FWI 21–37.9)
**Significant fire risk.** Fires can start easily and spread quickly.
- Avoid open burning
- Be extremely cautious with equipment that could spark
- Consider postponing higher-risk outdoor activities

---

## Very High (FWI 38–49.9)
**Dangerous conditions.** Fires can spread rapidly and be difficult to control.
- No open burning
- Stay alert for smoke or flames
- Check and follow any local restrictions

---

## Extreme (FWI 50+)
**Emergency conditions.** Fire behaviour can be extreme and unpredictable.
- Follow all emergency advice
- Be ready to leave the area if instructed
- Avoid activities that could cause ignition

---

## Important Notes

- These levels are based on weather conditions and vegetation moisture
- Local terrain, weather, and human activity can cause fire behaviour to differ from general forecasts
- Always follow official guidance from Scottish Fire and Rescue Service

To understand why risk levels change over time and location, see [Understanding Wildfire Risk](/help/doc/understanding-risk).

''';

const _understandingRiskContent = '''
# Understanding Wildfire Risk

Wildfire risk reflects how easily a fire could **start and spread if an ignition occurs**.  
It does **not** mean a fire is burning — it describes how dangerous conditions would be *if one started*.

Wildfire risk depends on multiple environmental factors working together.

---

## The Fire Weather Index (FWI)

The Fire Weather Index (FWI) is a scientifically validated system used across Europe.  
It combines weather and fuel conditions to estimate wildfire danger.

FWI considers:

1. **Temperature** — Higher temperatures dry out vegetation
2. **Humidity** — Low humidity means drier fuels
3. **Wind Speed** — Wind spreads fire and accelerates drying
4. **Precipitation** — Recent rainfall affects fuel moisture

---

## Why Risk Varies by Location

Wildfire risk can differ significantly even within short distances due to:

- **Vegetation type** — Heather and moorland behave differently from forests
- **Elevation** — Weather conditions change with altitude
- **Aspect** — South-facing slopes dry faster than shaded areas
- **Recent weather** — Days or weeks since meaningful rainfall

---

## Components of FWI

These components help explain why wildfire risk can remain high even after rain, or rise quickly during warm, windy weather.

### Fine Fuel Moisture Code (FFMC)
Measures moisture in surface litter and fine fuels (leaves, needles, grass)
- Responds quickly to daily weather changes
- Indicates how easily fires can ignite

### Duff Moisture Code (DMC)
Measures moisture in moderately deep organic layers
- Changes more slowly than FFMC
- Influences how deeply fires can burn

### Drought Code (DC)
Measures deep soil and large-fuel moisture
- Changes slowly over weeks
- Indicates long-term dryness and drought stress

---

## Limitations

The Fire Weather Index is a guide based on general environmental conditions.

- Actual fire behaviour depends on local terrain and fuel
- Microclimates can create very different conditions nearby
- Human activity remains the most common cause of wildfires
- The presence or absence of restrictions, permits, or fire bans is determined by authorities, not by this app

To see how these conditions translate into risk categories, see [What the Risk Levels Mean](/help/doc/risk-levels).

''';

const _weatherFuelFireContent = '''
# Weather, Fuel, and Fire

Wildfires don’t happen by accident. They occur when **weather conditions** and **available vegetation** combine in the wrong way.

In Scotland, this can happen quickly — sometimes after just a few dry or windy days.

---

## The Basics: What Fire Needs

For a wildfire to start and spread, three things must be present:

- **Heat** — an ignition source such as human activity or lightning  
- **Fuel** — vegetation that can burn  
- **Oxygen** — supplied and moved around by wind  

This is known as the **fire triangle**.  
Remove any one of these, and a fire cannot sustain itself.

---

## How Weather Influences Fire Risk

Weather controls how dry fuels become and how a fire behaves once started.

### Temperature
Warm conditions dry out vegetation over time.
- Heatwaves create especially dangerous conditions  
- Risk can still be high on cooler days after prolonged dry weather  
- Spring can be deceptive — dead grasses dry quickly even in mild temperatures  

### Wind
Wind is one of the most dangerous factors.
- Pushes flames and embers forward  
- Helps fires spread rapidly and change direction  
- Makes fires harder to control and more unpredictable  

Strong winds can turn small fires into major incidents very quickly.

### Humidity
Humidity affects how much moisture vegetation retains.
- Low humidity means fuels dry out faster  
- Humidity is often higher in the morning and lower in the afternoon  
- Inland areas can dry more quickly than coastal locations  

### Precipitation
Rain can reduce risk — but often only temporarily.
- Light or short rain may not reach deeper vegetation  
- A few dry days can undo the effects of rainfall  
- Wildfire risk reflects conditions over days and weeks, not just today’s weather  

---

## Fuel Types in Scotland

Different landscapes burn in different ways.

### Moorland and Heather
- One of the primary wildfire fuels in Scotland  
- Can burn intensely when dry  
- Managed burning (muirburn) reduces fuel under controlled conditions
- Often underlain by peat soils that can smoulder underground  

### Grassland
- Dries and ignites very quickly  
- Fires spread fast, especially in wind  
- Common along roadsides, paths, and field edges  

### Woodland
- Fallen leaves and needles can carry fire along the ground  
- Fires can climb into trees in extreme conditions  
- Conifer plantations can burn intensely once established 

## Peat and Underground Fire

Much of Scotland’s moorland sits on **peat soils**, which behave very differently from ordinary earth.

Peat can **smoulder underground**, holding heat long after surface flames appear to be extinguished.

### Why This Is Risky
- Peat fires often burn **below the surface**, with little or no visible flame  
- Heat can remain trapped even after rain or water is applied  
- Fires can **reignite hours or days later**, sometimes some distance away  

This means a campfire or BBQ that looks fully out can still start a wildfire later on.

### Common Causes
- Campfires built directly on the ground  
- Disposable BBQs placed on dry or peaty soils  
- Hot ash or embers buried or scattered  

Because peat fires are hidden, they are **hard to detect and extremely difficult to extinguish** once established.

### Why Prevention Matters
Peatlands store large amounts of carbon and support sensitive ecosystems.  
When they burn, the damage can be long-lasting.

This is why even small ignition sources can have serious consequences in peat-rich areas.


---

## Why This Matters

Most wildfires in Scotland are **started accidentally by people**, not by lightning.

Understanding how weather and fuel interact helps explain why:
- Fire bans remove ignition sources  
- Firebreaks remove fuel  
- Firefighting tactics aim to cool, smother, or slow a fire  

Even small actions can have serious consequences when conditions are right.

---

## In Summary

Wildfire risk isn’t about one hot day or one dry afternoon.  
It’s about how **weather**, **vegetation**, and **human activity** combine over time.

That’s why risk can change quickly — and why staying informed matters.

''';

const _seasonalGuidanceContent = '''
# Seasonal Guidance

## Key Dates

- **1 October–15 April**: Muirburn permitted (with conditions)
- **Scottish Outdoor Access Code**: Applies year-round
- **Cairngorms National Park fire bans**: 1st April–30 September
- **Other Local fire bans**: Check council announcements during high risk


**Wildfire risk in Scotland varies throughout the year. Here's what to expect:**


## Spring (February–May)

**Highest risk season**

Why:
- Dead grass from winter
- Vegetation hasn't greened up
- Dry east winds common
- Low humidity periods

Actions:
- Check fire risk before countryside visits
- Be extra careful with any ignition sources
- Traditional muirburn season — watch for controlled burns

## Summer (June–August)

**Variable risk**

Why:
- Vegetation is green but drought possible
- Tourism increases ignition risk
- BBQs and campfires more common
- Longer days = more outdoor activity

Actions:
- Check for local BBQ bans during dry spells
- Be careful with glass (can focus sunlight)
- Ensure campfires are fully extinguished
- Dispose of cigarettes properly

## Autumn (September–November)

**Secondary peak season**

Why:
- Vegetation curing (dying back)
- Dry conditions can persist from summer
- Stubble burning season on farms
- Dead bracken and ferns

Actions:
- Continue checking fire risk
- Be aware of agricultural burning
- Report any suspicious fires

## Winter (December–January)

**Generally lower risk**

Why:
- Wet, cool conditions
- Short days limit outdoor activity
- Snow cover in many areas

However:
- Dry cold spells can still create risk
- East coast can have dry winter periods
- Don't assume winter = no risk


''';

const _hotspotsContent = '''
## What Is a Hotspot?

A **hotspot** marks an area where a satellite detected unusually high surface temperatures.

Important points to understand:

- A hotspot is **not a confirmed wildfire**
- It may represent:
  - An active wildfire
  - Controlled burning (e.g. muirburn, stubble burning)
  - Industrial heat sources
- Some hotspots are **false positives**

### Detection Area Size

Most hotspots come from the **VIIRS satellite sensor**.

- Each detection covers an area of approximately **375 × 375 metres**
- The fire (if present) could be **anywhere within that area**
- The marker shows the **centre of detection**, not an exact location

Multiple nearby hotspots may indicate a larger or ongoing fire.

## Hotspot Information - shown on tap:

Each marker shows:
- **Location** — Where the heat was detected
- **Confidence** — How likely it's a real fire
- **Detection time** — When satellite passed over
- **Intensity** — Relative heat level

## Understanding Confidence

- **High confidence** — Very likely to be real fire activity
- **Moderate confidence** — Probable fire, some uncertainty
- **Low confidence** — Heat detected, may not be fire

## Limitations

- Satellites pass over at specific times, not continuously
- Cloud cover can block detection
- Small fires may not be detected
- Indoor/underground fires won't appear
- Detection is typically 6-24 hours behind real-time

## What to Do

**If you see a hotspot near you:**
1. Don't panic — it may be legitimate activity
2. Look for smoke or fire yourself
3. If you see an uncontrolled fire, call 999
4. Don't rely solely on app data

**If you see fire not on the map:**
1. The map may not be updated yet
2. Call 999 if it's uncontrolled
3. Use the Report feature for awareness
''';

const _burntAreaContent = '''
## What Is a Burnt Area?

A **burnt area** shows land that has already burned and has been mapped **after the fire is contained**.

- Burnt areas are **not active fires**
- They are produced by **EFFIS (Copernicus)** using satellite analysis
- Mapping often appears **days or weeks after** a fire event
- These areas show **fire extent**, not current conditions

Burnt areas help with:
- Understanding fire impact
- Land management and recovery
- Historical awareness

### Appearance on the Map
- Burnt areas are shown as **shaded polygons**
- Visible when zoomed in sufficiently

Each marker shows:
- **Date of burn** — When the fire occurred
- **Area size** — Approximate size of the burnt land
- **Vegetation type** — What kind of land was affected
- **Confidence level** — How certain the mapping is

### Limitations
- Not all fires are mapped (small or short-lived fires)
- Boundaries may be approximate
- Burnt areas do not indicate current fire risk

## What to Do

**If you see a burnt area near you:**
1. Understand it indicates past fire activity
2. Be cautious if visiting recently burnt land
3. Follow local guidance on access and safety
4. Report any new fires you observe

**If you see fire not on the map:**
1. The map may not be updated yet
2. Call 999 if it's uncontrolled
3. Use the Report feature for awareness
''';

const _dataSourcesHelpContent = '''
# Data Sources Explained

WildFire uses authoritative data sources to provide fire risk and hotspot information.

## Fire Weather Index Data

**Source**: European Forest Fire Information System (EFFIS)

EFFIS is operated by the European Commission's Joint Research Centre and provides:
- Daily fire danger forecasts
- Fire weather index calculations
- Coverage across Europe including Scotland

**Update frequency**: Daily (typically updated by 12:00 UTC)

## Satellite Hotspot Data

**Source**: NASA FIRMS (Fire Information for Resource Management System)

FIRMS processes data from:
- **MODIS** (Moderate Resolution Imaging Spectroradiometer)
- **VIIRS** (Visible Infrared Imaging Radiometer Suite)

These sensors are on NASA and NOAA satellites.

**Update frequency**: Multiple (6-8) times daily as satellites pass over

## Location Data

**Source**: Your device's GPS (with your permission)

Used for:
- Showing fire risk at your location
- Centering the map
- Calculating distances to hotspots

**Privacy**: Location data stays on your device. See our Privacy Policy.

## Limitations

- Forecast data is a model, not a direct measurement
- Satellite detection has inherent delays
- Resolution limits precise location of fires
- Data may not reflect very recent changes
- Local conditions can differ from regional forecasts

## Acknowledgments

We gratefully acknowledge:
- EFFIS/JRC for fire danger data
- NASA FIRMS for hotspot detection
- OpenStreetMap contributors for map tiles
''';

const _updateFrequencyContent = '''
# Update Frequency & Limits

Understanding how often data updates helps you use WildFire effectively.

## Fire Weather Index

- **Source updates**: Daily, typically by 12:00 UTC
- **App checks**: When you open the app or pull to refresh
- **Cache**: Data cached for up to 6 hours

The FWI is a forecast based on weather data, so values don't change minute-by-minute.

## Satellite Hotspots

- Updated **multiple times per day** as satellites pass overhead
- **Typical delay**: 6-24 hours from fire start to appearance
- Cloud cover or smoke can delay detection
- **App checks**: When you open the map or refresh

Why the delay?
1. Satellites orbit Earth, not hovering in place
2. Processing time for thermal imagery
3. Quality checks before data release

### Burnt Areas
- Updated **after fire containment**
- Not intended for live monitoring

## What This Means for You

### Don't Expect Real-Time
- The map is not a live video feed
- A live fire could exist that isn't shown yet
- Use your own observations alongside the app

### Check Before Activities
- Check in the morning for daily planning
- Refresh before heading out
- Don't assume yesterday's data is current

### Report What You See
- Your reports help fill gaps in satellite coverage
- Community awareness supplements official data
- Always call 999 for actual emergencies
''';

const _seeFireContent = '''
# What to Do if You See Fire

**If you can see flames, spreading fire, thick smoke, or you’re unsure — call 999.**

Emergency services would rather assess a call that turns out to be minor than miss a real wildfire.

---

## Quick Decision Guide

| What You See | Who to Call |
|--------------|-------------|
| 🔥 **Spreading fire, visible flames, immediate danger** | **999** — Fire Service |
| 🏕️ **Unattended or smouldering fire (not spreading)** | **101** — Police Scotland |
| 🔍 **Suspected deliberate fire-setting (anonymous)** | **0800 555 111** — Crimestoppers |

> **Not sure which number to use? Call 999.**  
> The operator will assess the situation and direct your call appropriately.

---

## If You Call 999 (What to Expect)

### 1. Ensure Your Safety First
- Move away from the fire
- Do not try to fight large fires yourself
- If smoke is thick, cover your mouth and nose

### 2. Ask for the Fire Service
Tell the operator:
- **“Fire service please”**
- Your location (as precisely as possible - this app gives you your coordinates)
- What is burning (grass, heather, woodland, buildings)
- How big the fire is and whether it’s spreading
- Wind direction, if known
- Whether people, animals, or buildings are at risk

### 3. Don’t Assume Someone Else Has Called
- Multiple calls help pinpoint the exact location
- Your information may be different or more accurate
- It’s always better to call than to wait

### 4. If Safe, Stay to Help Direct Crews
- Remain at a safe distance
- Make yourself visible if possible
- Provide updates if the fire spreads or conditions change

---

## When to Call Each Number

### 🚨 Call 999 (Fire Service) When:
- You see **flames spreading** across grass, heather, or woodland
- There is **thick smoke** and you can’t see the source
- A fire is **growing**, moving, or behaving unpredictably
- Buildings, roads, people, or animals are threatened
- You are **uncertain** how serious the situation is

**What to say:**
> “Fire service please. I can see [flames/smoke] at [location]. It appears to be [spreading/not spreading], and [describe what’s burning].”

---

### 📞 Call 101 (Police Scotland) When:
- You find an **unattended campfire** that is not spreading
- You see **smouldering embers or peat** that could reignite
- A fire appears **controlled but concerning**, with no immediate danger
- You want to report something **non-urgent**

**What to say:**
> “I’d like to report an unattended or concerning fire at [location]. It’s not spreading, but I’m worried it could become dangerous.”

---

### 🔒 Call Crimestoppers (0800 555 111) When:
- You believe a fire was **deliberately started**
- You’ve seen **suspicious behaviour** linked to fire-setting
- You want to report information **anonymously**

You won’t be asked for your name or personal details.  
Provide as much information as you can about what you saw, when, and where.

---

## What NOT to Do

- ❌ **Do not** try to fight large fires alone
- ❌ **Do not** drive or walk through smoke
- ❌ **Do not** wait to see if the fire spreads
- ❌ **Do not** go back for belongings
- ❌ **Do not** rely on this app instead of calling **999**

---

**If in doubt, always call 999.**  
Multiple calls help emergency services respond faster and more accurately.

''';

const _limitationsContent = '''
# Important Limitations

WildFire is an awareness tool with important limitations you should understand.

## This App DOES NOT:

### Replace Emergency Services
- Can't dispatch firefighters
- Reports don't go to 999
- Not monitored 24/7
- Always call 999 for emergencies

### Provide Real-Time Data
- Satellite data is hours behind reality
- FWI is a daily forecast
- Map may not show current fires
- Conditions change faster than updates

### Cover All Fires
- Small fires may not be detected
- Indoor fires won't appear
- Underground fires won't show
- Smoke can hide thermal signatures

### Guarantee Accuracy
- Data comes from third parties
- Models have inherent uncertainty
- False positives happen
- False negatives happen

## This App DOES:

### Provide Awareness
- General fire danger conditions
- Known hotspot locations
- Educational information
- Community reports

### Help with Planning
- Check before outdoor activities
- Understand seasonal patterns
- Learn about fire behaviour
- Find safety information

### Support Responsible Behaviour
- Encourages checking conditions
- Promotes fire safety awareness
- Links to official resources
- Reminds you to call 999

## Your Responsibilities

- Use common sense alongside app data
- Follow official guidance and restrictions
- Call 999 if you see an emergency
- Don't rely solely on any app for safety

## When in Doubt

If you're unsure about fire risk or see something concerning:
1. Err on the side of caution
2. Leave the area if uncomfortable
3. Call 999 if you see fire
4. Check official sources for bans/restrictions
''';

const _emergencyGuidanceContent = '''
# Emergency Guidance

Know what to do before an emergency happens.

## Emergency Numbers

### 999 — Police, Fire, Ambulance
- Use for all life-threatening emergencies
- Free from any phone
- Works even without mobile signal (tries all networks)

### 112 — European Emergency Number
- Works throughout Europe
- Same services as 999 in UK
- Can be useful if 999 doesn't connect

### 101 — Police Non-Emergency
- Suspicious activity
- Crime that's not in progress
- General enquiries

## If You Receive a Fire Warning

### From Emergency Services
- Follow instructions exactly
- Prepare to evacuate if advised
- Don't wait until the last minute
- Help neighbours who may need assistance

### General Preparation
- Know your evacuation routes
- Have important documents ready
- Keep phone charged
- Fill car with fuel during high-risk periods

## Evacuation Checklist

If told to evacuate:
- ☐ Take essential medications
- ☐ Take phone and charger
- ☐ Take ID and important documents
- ☐ Take water and snacks
- ☐ Take pet supplies if applicable
- ☐ Lock your home
- ☐ Follow designated evacuation routes
- ☐ Don't return until authorities say it's safe

## During a Wildfire Nearby

### If Told to Stay
- Close all windows and doors
- Turn off gas
- Fill sinks/baths with water (firefighting reserve)
- Move flammable items away from house
- Listen to radio/official channels

### If Told to Leave
- Leave immediately
- Turn on headlights (visibility in smoke)
- Close car windows
- Drive slowly and carefully
- Don't stop in the fire area

## After a Fire

- Don't return until authorities confirm it's safe
- Watch for hotspots and flare-ups
- Be careful of damaged structures
- Check on neighbours
- Document any damage for insurance

## Resources

- **Scottish Fire and Rescue Service**: firescotland.gov.uk
- **Met Office**: metoffice.gov.uk
- **Scottish Government**: gov.scot/emergency
''';
