# ha_terrarium

[![hacs_badge](https://img.shields.io/badge/HACS-Custom-orange.svg)](https://github.com/custom-components/hacs)

A Home Assistant custom integration for terrarium monitoring and control.

## Features

- **Sensors**: Temperature and humidity monitoring
- **Switches**: Control heating, misting, UV light, and basking light
- **Config Flow**: Easy setup through the Home Assistant UI

## Installation

### HACS (Recommended)

1. Open HACS in your Home Assistant instance.
2. Go to **Integrations** → click the three-dot menu → **Custom repositories**.
3. Add `https://github.com/gersseba/ha_terrarium` with category **Integration**.
4. Search for **Terrarium** and install it.
5. Restart Home Assistant.

### Manual

1. Copy the `custom_components/terrarium` folder into your Home Assistant `config/custom_components/` directory.
2. Restart Home Assistant.

## Configuration

1. Go to **Settings** → **Devices & Services** → **Add Integration**.
2. Search for **Terrarium** and follow the setup wizard.

## Entities

### Sensors

| Entity | Description |
|--------|-------------|
| `sensor.<name>_temperature` | Current temperature (°C) |
| `sensor.<name>_humidity` | Current relative humidity (%) |

### Switches

| Entity | Description |
|--------|-------------|
| `switch.<name>_heating` | Heating element on/off |
| `switch.<name>_misting` | Misting system on/off |
| `switch.<name>_uv_light` | UV light on/off |
| `switch.<name>_basking_light` | Basking light on/off |

## Development

### Extending device communication

The `TerrariumCoordinator._async_update_data` method in `__init__.py` is the place to add real sensor/device communication. Replace the placeholder return value with actual data fetched from your hardware.

Similarly, `async_turn_on` / `async_turn_off` in `switch.py` should send commands to your physical device.

## License

This project is licensed under the MIT License.