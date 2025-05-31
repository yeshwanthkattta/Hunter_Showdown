# 1st Annual Makerchip ASIC Design Showdown, 2025

# Overview

This repository is all you need to compete in the 1st Annual Makerchip ASIC Design Showdown. For Showdown details, see https://www.redwoodeda.com/showdown-info. Participants must monitor the #showdown channel in the [TL-Verilog User's Slack workspace](https://join.slack.com/t/tl-verilog-users/shared_invite/zt-4fatipnr-dmDgkbzrCe0ZRLOOVm89gA) for program updates.

In each match, your fleet of three ships battles another. You design the control circuitry for your autonomous spacecraft to outmaneuver and outwit your opponents'.

## Rules of Combat

Your three ships can:

- accelerate
- fire up, down, left, or right
- activate a shield
- activate cloaking

Each ship has a recharging energy supply. Each action costs energy. You might take an offensive strategy, firing often; you might take a defensive strategy, leaning heavily on your shields and cloaking; or you might focus on maneuverability. Your strategy is what sets you apart from your competition.

Your ships are able to monitor the positions of the other ships (unless cloaked) and whether they are cloaked. They know which ships have been destroyed (on both teams). They cannot see enemy bullets or shields.

Ships are destroyed when they are shot or when their hit box exits the play area.

Control circuits have inputs characterizing the visible the state of the system, and they provide outputs that affect this state on the next cycle. Acceleration is applied as an instantaneous burst that immediately affects velocity, which affects the position on the next cycle. The VIZ tab on a given cycle reflects the state as update by the inputs on that cycle.

The coordinate system is turned 180 degrees between the opponents, so the starting
ship coordinates are the same for both opponents.

Game parameters like hit box and board sizes can be found at the top of `showdown_lib.tlv`.

## Coding Your Control Circuits

You'll construct your control logic in a copy of either:

- `showdown_template.tlv` (to code your logic in TL-Verilog) or
- `showdown_verilog_template.tlv` (to code your logic in Verilog)

Comments in those files provide interface signal details.

## Should I use TL-Verilog or Verilog?

It's up to you. Possible reasons to use pure Verilog inlcude:

- *Familiarity:* You likely have experience with Verilog; not too many folks are experienced with the TL-Verilog language extensions yet.
- *AI Assistance:* LLMs understand Verilog far better than TL-Verilog today.
- *Googleability:* There's a world of information about Verilog, while TL-Verilog learning materials are limited.
- *Marketable Skills:* Employers generally look for Verilog experience today since they don't know better.

On the other hand, TL-Verilog offers:

- *Superior Capabilities:* TL-Verilog is much more powerful and simpler. You can do more with less.
- *Easier:* You can become comfortable with it in a week. Especially, if you don't already know Verilog, it can be easier to get going with TL-Verilog. Even if you know Verilog already, you'll probably make up for your one-week investment by the time you are finished coding.
- *Advanced Skills:* Use this contest as an opportunity to learn something new and amp up your game.
- *Differentiation:* While mainstream employers look for Verilog designers, employers who are on the forefront of technology value advance skills with differentiated technology. Learning TL-Verilog could help you reach these employers and differentiate yourself from the masses.
- *Community:* This contest is associated with the TL-Verilog community. In the #showdown Slack channel in the [TL-Verilog User's Slack workspace](https://join.slack.com/t/tl-verilog-users/shared_invite/zt-4fatipnr-dmDgkbzrCe0ZRLOOVm89gA) you'll find a supportive community around TL-Verilog.
- *IDE Features:* This contest uses the Makerchip IDE, which is custom built to support TL-Verilog. Features like the DIAGRAM view and interactive features apply only to TL-Verilog.
- *Compatibility:* If you are on the fence, start with the TL-Verilog template and try using TL-Verilog. It is an extension of Verilog. If you have trouble, you can always write a pure Verilog component (module, macro, function, etc.) and instantiate it from your TL-Verilog code.

If you are coding (System)Verilog, you can find plenty of resources online. If you are learning TL-Verilog for the first time, you'll find
resources to get you started under Makerchip's "Learn" menu.

## Tips

### TL-Verilog

In the WAVEFORM viewer, using the template, your signals will appear under `TLV/secret/team0` or `/secret/team1`. Other signals will not be accessible to you. Though in the template, you can access them through `/secret`, for final competition, `/secret` will be renamed. Your design will not compile for competition if you attempt to access `/secret` signals.

Spend the time to learn TL-Verilog first, if you are not already familiar. There are learning resources in the Makerchip IDE. For this competition, you can build reasonable circuits as combinational logic, so pipelines, sequential logic, "alignment", and states are likely unimportant. Hierarchy will be useful to learn. Other tutorial topics, validity, TLV macros, and transaction flow, though they may be used heavily by the Showdown library and template, are less important for your logic.

If you don't know Verilog syntax, TL-Verilog uses Verilog `assign` expression syntax, so you learn this as well.

### Verilog

In the WAVEFORM viewer, you can find your signals under `SV.team_YOUR_GITHUB_ID` (which you must rename accordingly).

The internet can help you learn Verilog.

### Seeking Help

Seek help in Slack. Help others. A bit of competition can add to the fun, but the spirit of the competition is collaboration and community building.

## Competition Rules

Details of the competition structure will be determined close to the competition date, depending upon participation. Makerchip is the judge and jury for battles. The winner of each battle is the player/team who destroys all enemy ships or has the most ships remaining at (roughly) Makerchip's cycle limit of ~600 cycles.

Your submission must be based on the latest Verilog or TL-Verilog template. Bug fixes in the templates and Showdown library may be required during the coding period.

Inconsiderate behavior will not be tolerated and may result in disqualification. In the event of logic bugs, disputes, ambiguity, disqualification, etc., Redwood EDA, LLC's decisions are final and may result in lose of prize money.
