"""Switch platform for the Terrarium integration."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable

from homeassistant.components.switch import SwitchEntity, SwitchEntityDescription
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from .const import DOMAIN
from . import TerrariumCoordinator


@dataclass(frozen=True)
class TerrariumSwitchEntityDescription(SwitchEntityDescription):
    """Describe a Terrarium switch entity."""

    value_fn: Callable[[dict], bool] = lambda data: False


SWITCH_DESCRIPTIONS: tuple[TerrariumSwitchEntityDescription, ...] = (
    TerrariumSwitchEntityDescription(
        key="heating",
        name="Heating",
        icon="mdi:radiator",
        value_fn=lambda data: bool(data.get("heating")),
    ),
    TerrariumSwitchEntityDescription(
        key="misting",
        name="Misting",
        icon="mdi:water-spray",
        value_fn=lambda data: bool(data.get("misting")),
    ),
    TerrariumSwitchEntityDescription(
        key="uv_light",
        name="UV Light",
        icon="mdi:lightbulb-on",
        value_fn=lambda data: bool(data.get("uv_light")),
    ),
    TerrariumSwitchEntityDescription(
        key="basking_light",
        name="Basking Light",
        icon="mdi:white-balance-sunny",
        value_fn=lambda data: bool(data.get("basking_light")),
    ),
)


async def async_setup_entry(
    hass: HomeAssistant,
    entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up Terrarium switch entities."""
    coordinator: TerrariumCoordinator = hass.data[DOMAIN][entry.entry_id]

    async_add_entities(
        TerrariumSwitchEntity(coordinator, entry, description)
        for description in SWITCH_DESCRIPTIONS
    )


class TerrariumSwitchEntity(CoordinatorEntity[TerrariumCoordinator], SwitchEntity):
    """Representation of a Terrarium switch."""

    entity_description: TerrariumSwitchEntityDescription
    _attr_has_entity_name = True

    def __init__(
        self,
        coordinator: TerrariumCoordinator,
        entry: ConfigEntry,
        description: TerrariumSwitchEntityDescription,
    ) -> None:
        """Initialize the switch."""
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
    def is_on(self) -> bool:
        """Return true if the switch is on."""
        return self.entity_description.value_fn(self.coordinator.data)

    async def async_turn_on(self, **kwargs: Any) -> None:
        """Turn the switch on."""
        # Extend this method to send a command to your real device.
        await self.coordinator.async_request_refresh()

    async def async_turn_off(self, **kwargs: Any) -> None:
        """Turn the switch off."""
        # Extend this method to send a command to your real device.
        await self.coordinator.async_request_refresh()
