"""Constants for the Terrarium integration."""

DOMAIN = "terrarium"

# Configuration keys
CONF_NAME = "name"
CONF_TEMPERATURE_SENSOR = "temperature_sensor"
CONF_HUMIDITY_SENSOR = "humidity_sensor"

# Default values
DEFAULT_NAME = "Terrarium"
DEFAULT_SCAN_INTERVAL = 30  # seconds

# Platforms
PLATFORMS = ["sensor", "switch"]

# Sensor types
SENSOR_TEMPERATURE = "temperature"
SENSOR_HUMIDITY = "humidity"

# Switch types
SWITCH_HEATING = "heating"
SWITCH_MISTING = "misting"
SWITCH_UV_LIGHT = "uv_light"
SWITCH_BASKING_LIGHT = "basking_light"

# Attributes
ATTR_TEMPERATURE = "temperature"
ATTR_HUMIDITY = "humidity"
ATTR_LAST_UPDATED = "last_updated"
