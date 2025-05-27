\m5_TLV_version 1d: tl-x.org
\m5
   / A competition template for the First Annual Makerchip ASIC Design Showdown, Summer 2025, Space Battle.
   / Each player provides a contestant library based on the corresponding player_template.tlv
   / containing the spacecraft control circuit.

   /-------------------------------------------+-------------------------------------------\
   /                                                                                       |
   /      Your job is to write logic to pilot your ships to destroy the enemy ships!       |
   /                                                                                       |
   /                                                                                       |
   /   You can define the following signals:                                               |
   /   - $xx_a: ship's x-axis acceleration                                                 |
   /   - $yy_a: ship's y_axis acceleration                                                 |
   /   - $attempt_shield: activate ship's shield if not on cooldown (The shield cools      |
   /   down for 4 cycles, charges up for 10, and stays active depending on how long it     |
   /   was changed up for)                                                                 |
   /   - $attempt_fire: fire one of the ship's bullets if one is available (each ship      |
   /   can have 3 bullets on screen at once)                                               |
   /   - $fire_dir: the direction in which the ship fires its bullet                       |
   /                                                                                       |
   /   Additional information:                                                             |
   /   - Ship dimensions are 10x10                                                         |
   /   - Bullet dimensions are 2x16                                                        |
   /   - Bullets move 16 tiles per cycle                                                   |
   /                                       Good luck!                                      |
   /                                                                                       |
   /-------------------------------------------+-------------------------------------------/

   use(m5-1.0)
   
   / Instructions:
   / Substitute URLs for the player circuits here, the first plays first as green, the second as orange.
\SV
   // Include the game.
   m4_include_lib(https://raw.githubusercontent.com/PigNeck/space-scuffle/refs/heads/main/space_invaders_lookin_ahh.v)
\SV
   // Macro providing required top-level module definition and random stimulus support.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   // Instantiate the Showdown environment.
   m5+showdown(/top, /showdown,
      /// A tag used to hide opponent logic that will be given an unknown value in competition.
      hidden,
      /// Team 1's logic (or empty for random opponent):
      https://raw.githubusercontent.com/stevehoover/drop4game/6baddeb046a3e261bb45bbc2cb879cd8c9931778/player_template.tlv,
      /// Team 2's logic (or empty for random opponent):
      https://raw.githubusercontent.com/stevehoover/drop4game/6baddeb046a3e261bb45bbc2cb879cd8c9931778/player_template.tlv)
\SV
   endmodule