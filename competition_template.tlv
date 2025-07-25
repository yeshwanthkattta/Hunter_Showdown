\m5_TLV_version 1d: tl-x.org
\m5
   / A template for players/teams to compete in:
   /
   / /----------------------------------------------------------------------------\
   / | The First Annual Makerchip ASIC Design Showdown, Summer 2025, Space Battle |
   / \----------------------------------------------------------------------------/
   /
   / Showdown details: https://www.redwoodeda.com/showdown-info and in the repository README.
   /
   / Each team provides their control logic in a file on GitHub based on:
   / https://github.com/rweda/showdown-2025-space-battle/blob/main/showdown_template.tlv
   /
   / Instructions for configuring the battle: Follow STEP 1 and STEP 2 below.

   use(m5-1.0)
   
   var(viz_mode, demo)  /// Enables VIZ for development.
                        /// Use "devel" or "demo". ("demo" will be used in competition.)
\SV
   // STEP 1: Include URLs for the player circuits (raw files from GitHub).
   m4_include_lib(https://raw.githubusercontent.com/rweda/showdown-2025-space-battle/main/sample_players/random.tlv)
   m4_include_lib(https://raw.githubusercontent.com/rweda/showdown-2025-space-battle/main/sample_players/random.tlv)

   // Include the Showdown framework.
   m4_include_lib(https://raw.githubusercontent.com/rweda/showdown-2025-space-battle/6131e647214fe286616e51542d511cc49ed3fdc2/showdown_lib.tlv)
   
   m5_makerchip_module
\TLV

   // STEP 2: Enlist teams for battle.
   // Replace GITHUB_IDs and TEAM_NAMEs matching the included files.
   m5_team(YOUR_GITHUB_ID, YOUR_TEAM_NAME)
   m5_team(THEIR_GITHUB_ID, THEIR_TEAM_NAME)
   
   
   // Instantiate the Showdown environment.
   m5+showdown(/top, /secret)
   
   *passed = /secret$passed;   // Defines max cycles, up to ~600.
   *failed = /secret$failed;
\SV
   endmodule
   // Declare Verilog modules.
   m4_ifdef(['m5']_team_\m5_get_ago(github_id, 0)_module, ['m5_call(team_\m5_get_ago(github_id, 0)_module)'])
   m4_ifdef(['m5']_team_\m5_get_ago(github_id, 1)_module, ['m5_call(team_\m5_get_ago(github_id, 1)_module)'])
