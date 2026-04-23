"""Sensor platform for the Terrarium integration."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

from homeassistant.components.sensor import (
    SensorDeviceClass,
    SensorEntity,
    SensorEntityDescription,
    SensorStateClass,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import PERCENTAGE, UnitOfTemperature
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from .const import DOMAIN
from . import TerrariumCoordinator


@dataclass(frozen=True)
class TerrariumSensorEntityDescription(SensorEntityDescription):
    """Describe a Terrarium sensor entity."""

    value_fn: Callable[[dict], float | None] = lambda data: None


SENSOR_DESCRIPTIONS: tuple[TerrariumSensorEntityDescription, ...] = (
    TerrariumSensorEntityDescription(
        key="temperature",
        name="Temperature",
        device_class=SensorDeviceClass.TEMPERATURE,
        state_class=SensorStateClass.MEASUREMENT,
        native_unit_of_measurement=UnitOfTemperature.CELSIUS,
        value_fn=lambda data: data.get("temperature"),
    ),
    TerrariumSensorEntityDescription(
        key="humidity",
        name="Humidity",
        device_class=SensorDeviceClass.HUMIDITY,
        state_class=SensorStateClass.MEASUREMENT,
        native_unit_of_measurement=PERCENTAGE,
        value_fn=lambda data: data.get("humidity"),
    ),
)


async def async_setup_entry(
    hass: HomeAssistant,
    entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up Terrarium sensor entities."""
    coordinator: TerrariumCoordinator = hass.data[DOMAIN][entry.entry_id]

    async_add_entities(
        TerrariumSensorEntity(coordinator, entry, description)
        for description in SENSOR_DESCRIPTIONS
    )


class TerrariumSensorEntity(CoordinatorEntity[TerrariumCoordinator], SensorEntity):
    """Representation of a Terrarium sensor."""

    entity_description: TerrariumSensorEntityDescription
    _attr_has_entity_name = True

    def __init__(
        self,
        coordinator: TerrariumCoordinator,
        entry: ConfigEntry,
        description: TerrariumSensorEntityDescription,
    ) -> None:
        """Initialize the sensor."""
        super().__init__(coordinator)
        self.entity_description = description
        self._attr_unique_id = f"{entry.entry_id}_{description.key}"
        self._attr_device_info = {
            "identifiers": {(DOMAIN, entry.entry_id)},
            "name": entry.title,
            "manufacturer": "Terrarium",
            "model": "Terrarium Controller",
        }

    @property
    def native_value(self) -> float | None:
        """Return the sensor value."""
        return self.entity_description.value_fn(self.coordinator.data)
