ZONE_MESSAGES = {
    'outside_monitored_hazard_zone': (
        'You are outside the monitored hazard zone. No immediate landslide or flood risk '
        'is detected for your current location.'
    ),
}

RISK_MESSAGES = {
    'NO RISK': (
        'No significant hazard risk is detected at your current location. Conditions appear '
        'safe based on the latest available data.'
    ),
    'LOW': (
        'A low level of risk has been detected in your area. There is no immediate danger, '
        'but you should remain aware of weather and ground conditions.'
    ),
    'MODERATE': (
        'A moderate hazard risk has been detected for your location. Avoid travelling through '
        'landslide-prone roads, steep slopes, and low-lying flood areas.'
    ),
    'HIGH': (
        'A high hazard risk has been detected near your location. Move away from dangerous '
        'slopes, riverbanks, and unstable roads as soon as it is safe to do so.'
    ),
}


def get_safety_message(risk_level, zone_status=None):
    if zone_status == 'outside_monitored_hazard_zone':
        return ZONE_MESSAGES[zone_status]
    return RISK_MESSAGES.get(risk_level, RISK_MESSAGES['NO RISK'])
