# xAbilityPulse
A Firefall addon that briefly overlays the icon of an ability in the center of the screen whenever it comes back off cooldown, including abilities with charges.

## Compatability Notes
Compatible with Firefall Stabilization (v1.5.1350).

This addon was developed on the Firefall PTS (stabilization-1334) and will presently not function on the live servers (v1.3.1869).

##Interface Options
| Option  | Description |
|------------- | ------------- |
| Enable addon | If unchecked, the addon will stop tracking cooldowns, stopping normal operations. |
| Enable debug | If checked, the addon will enable debug logging and possibly also output debug messages to the system channel. |
| Check version on load | If checked, the addon will query GitHub for the version number of the latest relase and notify you if it differs from your local version, once everytime the addon is loaded. |
| Always display pulses | If checked, the addon may display pulses during in-game cinematics, etc. |
| Pulse for medical system cooldown | If checked, the addon will also pulse when your medical system comes off cooldown. |
| Pulse for auxiliary weapon cooldown | If checked, the addon will also pulse when your auxiliary weapon comes off cooldown. |
| Icon size scale | The slider allows you to scale the size of the ability icon. |
| Icon alpha | The slider allows you to set the target alpha for the icon fade in effect. |
| Icon fade in duration | The slider allows you to set the duration of the icon fade in effect. |
| Icon fade out duration | The slider allows you to set the duration of the icon fade out effect. |

###Moveable Frame
You can adjust the position of the icon through the interface options menu, by moving the frame labeled "Ability Pulse" to the desired location. Please note that the size of this frame is not indicative of the size of the icon.

##Slash Commands
**Slash handles**: xap, xabilitypulse, abilitypulse

| Command  | Description |
|------------- | ------------- |
|/xap test     | Picks and plays a random ability pulse outside of the cooldown tracking. |
|/xap scale <value> | Sets the scale of the ability icon. Value between 1-200 recommended. |
|/xap version | Queries GitHub for the version number of the latest relase and informs you if it differs from your local version |
