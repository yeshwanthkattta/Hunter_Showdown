# 1st Annual Makerchip ASIC Design Showdown, 2025

This repository is all you need to compete in the 1st Annual Makerchip ASIC Design Showdown. For Showdown details, see https://www.redwoodeda.com/showdown-info.

## The 2025 Challenge Theme -- Space Battle

In each match, your fleet of three ships battles another. You design the control circuitry for your autonomous spacecraft to outmaneuver your opponents'.

## Rules of Battle

Your three ships can:

- accelerate
- fire up, down, left, or right
- activate a shield
- activate cloaking

Each ship has a recharging energy supply. Each action costs energy. You might take an offensive strategy, firing often; you might take a defensive strategy, leaning heavily on your shields and cloaking; or you might focus on maneuverability. Your strategy is what sets you apart from your competition.

Your ships are able to monitor the last known positions of the other ships and whether they are cloaked (in which case their current positions are unknown). They cannot see enemy bullets or shields.

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

## Getting Started with TL-Verilog

If you are coding (System)Verilog, you can find plenty of resources online. If you are learning TL-Verilog for the first time, you'll find
resources to get you started under Makerchip's "Learn" menu.
