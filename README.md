# Buffer Time

This plugin is will show you your current *Buffer Time* compared to a reference player/ghost.
Compatible modes: Knockout (incl COTD), Time Attack, Campaign, and more can be added in the future upon request.
This plugin packages lore-abiding fonts that are monospaced for a pleasant visual experience.

**(If this plugin does not seem to work for you, make sure you've installed MLHook and MLFeed: Race Data.)**

The reference player/ghost is contextual: in COTD KO it is the player just below the cutoff if you're ahead (and just above the cutoff if you're behind); in Time Attack it's your current best time, and/or PB, and/or a ghost of your choosing.

In some modes (like TA/Campaign), a secondary buffer time can optionally be shown as well.
This means you can see your current progress compared to both your PB and the WR at the same time.
(Note: you have to enable the ghost once on that server until the map changes.)

This plugin can function as a replacement for checkpoint splits all together in supported game modes (if you like to play with the interface off, for example).

### *__IMPORTANT:__ This plugin depends on __MLHook__ v0.3.0+ and __MLFeed: Race Data__. You must also install those plugins.*

If you don't, at best you'll get a polite notification and at worst you'll get a compile error.

### Before Version 2

This plugin began as a clone of [COTD Delta time](https://openplanet.dev/plugin/cotddeltako).
Buffer Time was written because COTD Delta time started crashing my game on the first CP (some of the time) ([github issue for PlayerState](https://github.com/thommie-echo/TMNext-PlayerState/issues/11)).


### 'About'-type stuff

License: Public Domain

Authors: XertroV

Suggestions/feedback: @XertroV on Openplanet discord

Code/issues: [https://github.com/XertroV/tm-cotd-buffer-time](https://github.com/XertroV/tm-cotd-buffer-time)

GL HF


<!--

Buffer Time; Checkpoint Alternative for COTD, TA, KO, Campaign

An alternative to checkpoints; shows Buffer Time compared to a reference. In COTD / KO, it shows how far you are from elimination. In TA / Solo, the reference is a ghost of your choosing, your PB, etc, and a secondary timer is available.

- tmp disable option?
- reference: best time on server?
- [done] track priority choices and auto repopulate better
- [done] fix PB ghost issue in Solo?
- [done] show final time

-->
