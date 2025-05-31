\m5_TLV_version 1d: tl-x.org
\m5
   / The First Annual Makerchip ASIC Showdown, Summer 2025: Space Battle
   / This file is the library providing the content.
   / See the repo's README.md for more information.
   use(m5-1.0)
   
   / +++++++++++ Game Parameters ++++++++++++
   
   define_hier(SHIP, 3, 0)   /// number of ships
   
   / The board (play area) is 128x128, centered at 0,0.
   
   / Ship and bullet hit box width/height
   var(ship_width, 8)
   var(ship_height, 8)
   var(bullet_width, 2)
   var(bullet_height, 10)
   / Bullets travel (ship_height + bullet_height) / 2 = 9 each cycle.
   
   / Energy Supply
   var(reset_energy, 40)   /// your initial energy
   var(max_energy, 80)     /// your maximum energy
   var(recoup_energy, 15)  /// the amount you recharge each clock cycle, capped by max_energy.
   / Energy is adjusted by each of the following each cycle, after recouping and maxing, in this order.
   / Any action that would take energy below zero cannot be taken.
   / Acceleration costs energy equal to X acceleration + Y acceleration. If there is insufficient energy for all acceleration, no acceleration is applied.
   var(fire_cost, 30)      /// the energy cost of firing
   var(cloak_cost, 15)     /// the energy cost of cloaking (each active cycle)
   var(shield_cost, 25)    /// the energy cost of using your shield (each active cycle)
   
   define_hier(BULLET, 3, 0)    /// max number of bullets
   
   / ++++++++++ End of Contest Parameters ++++++++++++
   
   
   / Computed parameters.
   var(half_bullet_width, m5_calc(m5_bullet_width / 2))
   var(half_bullet_height, m5_calc(m5_bullet_height / 2))
   var(half_ship_width, m5_calc(m5_ship_width / 2))
   var(half_ship_height, m5_calc(m5_ship_height / 2))
   
   var(default_anim_duration, 250)
   var(default_anim_easing, easeOutCubic)  /// e.g. easeOutCubic or linear
   
   
   / Provide a library defining a team's control circuit, name, and ID.
   fn(team_raw_tlv, ?TlvFile, {
      / Include submitted TLV URL, reporting an error if it produces text output.
      if_null(m4_include_lib(_team1_lib), [
         error(['The following TL-Verilog library produced output text. Ignoring']m5_nl    m5_TlvFile)
      ])
      on_return(var, github_id, m5_github_id)   /// Preserve what the library defined after it gets popped by the return.
      on_return(var, team_name, m5_team_name)   ///   "
   })
   
   / Define which TLV macro to use for this team.
   / E.g. m5_team_macro(random)  /// For predefined random opponent.
   fn(team, TeamId, TeamName, {
      on_return(var, github_id, m5_TeamId)
      on_return(var, team_name, m5_TeamName)
   })
   
   // Verilog sign extend.
   macro(sign_extend, ['{{$3{$1[$2]}}, $1}'])
   
   // Get the current and previous (from which VIZ cycle) value of a signal.
   fn(get_sig, Path, Sig, Type, {
      ~($m5_Sig = 'm5_Path$m5_Sig'; const is_\m5_Sig = $m5_Sig.as\m5_Type[''](); const was_\m5_Sig = $m5_Sig.step(step).as\m5_Type['']();)
   })

// --------------- For the Verilog template ---------------

// Search and replace all YOUR_GITHUB_ID with your GitHub ID, excluding non-word characters
// (alphabetic, numeric, and "_" only)
\TLV verilog_wrapper(/_top, _github_id)
   \SV_plus
      team_['']_github_id team_['']_github_id(
         // Inputs:
         .clk(clk),
         .reset(/_top$reset),
         .x_v(/ship[*]$xx_v),
         .y_v(/ship[*]$yy_v),
         .energy(/ship[*]$energy),
         .destroyed(/ship[*]$destroyed),
         .enemy_x_p(/enemy_ship[*]$xx_p),
         .enemy_y_p(/enemy_ship[*]$yy_p),
         .enemy_cloaked(/enemy_ship[*]>>1$do_cloak),
         // Outputs:
         .x_a($$xx_a_vect[4*m5_SHIP_CNT-1:0]),
         .y_a($$yy_a_vect[4*m5_SHIP_CNT-1:0]),
         .attempt_fire(/ship[*]$$attempt_fire),
         .attempt_shield(/ship[*]$$attempt_shield),
         .attempt_cloak(/ship[*]$$attempt_cloak),
         .fire_dir($$fire_dir_vect[2*m5_SHIP_CNT-1:0])
      );
   /ship[*]
      $xx_a[3:0] = /_top$xx_a_vect[4 * (#ship + 1) - 1 : 4 * #ship];
      $yy_a[3:0] = /_top$yy_a_vect[4 * (#ship + 1) - 1 : 4 * #ship];
      $fire_dir[1:0] = /_top$fire_dir_vect[2 * (#ship + 1) - 1 : 2 * #ship];



// --------------- Sample player logic ---------------

// Team logic providing random behavior.
\TLV team_random(/_top)
   /ship[*]
      m4_rand($rand, 31, 0, ship)
      $xx_a[3:0] = $rand[3:0];
      $yy_a[3:0] = $rand[7:4];
      $attempt_fire = $rand[8];
      $fire_dir[1:0] = $rand[10:9];
      $attempt_shield = $rand[11];
      $attempt_cloak = $rand[12];

// Team logic providing testing behavior.
\TLV team_test1(/_top)
   /ship[*]
      $fire_counter[1:0] = >>1$reset ? 2'b0 :
                           (>>1$fire_counter + 2'b1);
      $ability_counter[3:0] = >>1$reset ? 4'b0 :
                             (>>1$ability_counter + 4'b1);
      
      ///m4_rand($rand, 31, 0)
      $xx_a[3:0] = >>1$reset ? 4'b11 :
         ((>>1$xx_p + 8'b10000000) > (8'd32 + 8'b10000000)) ? 4'b1101 :
         ((>>1$xx_p + 8'b10000000) < (- 8'd32 + 8'b10000000)) ? 4'b11 :
         4'b0;
      
      $yy_a[3:0] = >>1$reset ? 4'b11 :
         ((>>1$yy_p + 8'b10000000) > (- 8'd22 + 8'b10000000)) ? 4'b1101 :
         ((>>1$yy_p + 8'b10000000) < (- 8'd48 + 8'b10000000)) ? 4'b11 :
         4'b0;
      
      $attempt_fire = ($fire_counter == 2'b11);
      $fire_dir[1:0] = 2'b11; //0 = right, 1 = down, 2 = left, 3 = up
      
      $attempt_shield = ($ability_counter >= 4'b101) && ($ability_counter < 4'b1000);
      
      $attempt_cloak = ($ability_counter >= 4'b1101);

// Team logic that uses default values (and thus, the ships do absolutely nothing).
\TLV team_sitting_duck(/_top)
   /ship[*]

// ------------------- End of sample player logic -----------------------



// Macro to instantiate and connect up the logic for both players.
\TLV player_logic(/_secret, /_name, _team_num)
   /_name
      m5_var(enemy_num, m5_calc(1 - _team_num))
      m5_push_var(my_ship, /_secret/player[_team_num]/ship[#ship])
      m5_push_var(enemy_ship, /_secret/player[m5_enemy_num]/ship[#enemy_ship])
      $reset = /_secret$reset;
      `BOGUS_USE($reset)
      
      // State that is accessible to contestants.
      /m5_SHIP_HIER    // So team code can use /ship[*].
         $reset = /_secret$reset;
         
         // Provide default control output signal values.
         $ANY = /_secret/default_controls$ANY;
         
         // Provide visibility to own ship state. These all come from m5_\my_ship, but we don't use $ANY to avoid exposing private state.
         // Also, we apply cloaking to position.
         $xx_p[7:0] = m5_my_ship$xx_p;
         $yy_p[7:0] = m5_my_ship$yy_p;
         $xx_v[5:0] = m5_my_ship$xx_v;
         $yy_v[5:0] = m5_my_ship$yy_v;
         $energy[7:0] = m5_my_ship$energy;
         $destroyed = m5_my_ship$destroyed;
         // The above do not have to be used.
         `BOGUS_USE($reset $xx_p $yy_p $xx_v $yy_v $energy $destroyed)
      
      // Provide visibility to enemy ship state.
      /enemy_ship[m5_SHIP_RANGE]
         $enemy_visible = m5_enemy_ship$do_cloak || m5_enemy_ship$destroyed;
         $xx_p[7:0] = $enemy_visible ? >>1$xx_p : m5_enemy_ship$xx_p;
         $yy_p[7:0] = $enemy_visible ? >>1$yy_p : m5_enemy_ship$yy_p;
         $destroyed = m5_enemy_ship$destroyed;
         // The above do not have to be used.
         `BOGUS_USE($xx_p $yy_p $destroyed)
      
      m5_pop(my_ship, enemy_ship)   /// To avoid exposure to secret.
      // ------ Instantiate Team Macro ------
      m5+call(team_\m5_get_ago(github_id, m5_enemy_num), /_name)

\TLV showdown(/_top, /_secret)
   /// Each team submits a file containing a TLV macro whose name is the GitHub ID matching the
   /// repository and the submission (omitting unsupported characters, like '-'), as:
   /// var(github_id, xxx)
   /// \TLV team_xxx()
   ///    ...
   
   /// Make sure both teams defined their github_id and team_name.
   m5_if_neq(m5_depth_of(github_id), 2, ['m5_error(['Need two teams defined, but have definitions for ']m5_depth_of(github_id)[' github_id's.'])'])
   m5_if_neq(m5_depth_of(team_name), 2, ['m5_error(['Need two teams defined, but have definitions for ']m5_depth_of(team_name)[' team_name's.'])'])
   
   $raw_reset = *reset;
   $reset = >>1$raw_reset;  // delay 1 cycle to see initial state in VIZ.
   
   /_secret
      // These provide defaults for the team control logic.
      /default_controls
         $attempt_fire = 1'b0;
         $xx_a[3:0] = 4'b0;
         $yy_a[3:0] = 4'b0;
         $fire_dir[1:0] = 2'b0;
         $attempt_shield = 1'b0;
         $attempt_cloak = 1'b0;
         $dummy = 1'b0;  // A dummy signal to ensure something is pulled through the $ANY.
         // These do not have to be (in fact, should not) be used.
         `BOGUS_USE($attempt_fire $xx_a $yy_a $fire_dir $attempt_shield $attempt_cloak)

      $reset = /_top$reset;
      m5+player_logic(/_secret, /team0, 0)
      m5+player_logic(/_secret, /team1, 1)

      /background
         // ================  BACKGROUND VIZ  ================
         \viz_js
            box: { left: -128, top: -128, width: 256, height: 256, strokeWidth: 0 },
         
         
            // ~~~~~~~~ Init ~~~~~~~~
            init()
            {
               let background = this.newImageFromURL(
                  "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/back_grid_small.png",
                  "",
                  {
                     originX: "center", originY: "center",
                     left: 0, top: 0,
                     width: 128, height: 128,
                     imageSmoothing: false,
                  }
               );
         
               return { background_img: background };
            }

      // Win logic:
      $win_id[1:0] = /player[0]$lost ?
                        /player[1]$lost ? 2'b11 :
                        2'b01 :
                     /player[1]$lost ? 2'b10 :
                     2'b00;
      
      
      // ||||||||||||||||  PLAYER LOGIC ||||||||||||||||
      /player[1:0]
         $player_id = (#player != 0);
         $lost = (& /ship[*]$destroyed);
         
         /other_player
            //$ANY = /player[!/player$player_id]$ANY;
            
            /m5_SHIP_HIER
               $ANY = /player[! /player$player_id]/ship$ANY;
         
         
         // ================  PLAYER VIZ  ================
         \viz_js
            box: { strokeWidth: 0},
         
            // This just flips the ships for the second player. There isn't any other viz for the player directly.
            layout: { left: 256, top: 256, angle: 180 },
         
         /m5_SHIP_HIER
            $reset = /_top$reset;
            
            // Inputs from team logic.
            $ANY = /player$player_id ? /_secret/team1/ship$ANY : /_secret/team0/ship$ANY;
            `BOGUS_USE($dummy)  // Make sure this is pulled through the $ANY chain from /defaults to prevent empty $ANYs.
            
            // Recoup energy, capped by max.
            $recouped_energy[7:0] = $Energy + 8'd\m5_recoup_energy;
            $maxed_energy[7:0] = ($recouped_energy > 8'd\m5_max_energy) ? 8'd\m5_max_energy : $recouped_energy;
            // Accelerate
            $no_more_bullets = & /bullet[*]$bullet_exists;
            $do_accelerate = $maxed_energy >= $xx_a + $yy_a && ! $destroyed;
            $energy_after_a[7:0] = $maxed_energy - ($do_accelerate ? m5_sign_extend($xx_a, 3, 4) + m5_sign_extend($yy_a, 3, 4) : 8'b0);
            // Fire
            $do_fire = $attempt_fire && $energy_after_a >= 8'd\m5_fire_cost && ! $no_more_bullets && ! $destroyed;
            $energy_after_fire[7:0] = $energy_after_a - ($do_fire ? 8'd\m5_fire_cost : 8'b0);
            // Cloak
            $do_cloak = $attempt_cloak && $energy_after_fire >= 8'd\m5_cloak_cost && ! $destroyed;
            $energy_after_cloak[7:0] = $energy_after_fire - ($do_cloak ? 8'd\m5_cloak_cost : 8'b0);
            // Shield
            $do_shield = $attempt_shield && $energy_after_cloak >= 8'd\m5_shield_cost && ! $destroyed;
            $energy_after_shield[7:0] = $energy_after_cloak - ($do_shield ? 8'd\m5_shield_cost : 8'b0);
            
            $Energy[7:0] <= $reset ? 8'd40 :
               $energy_after_shield;
            
            // Is accessible, but not directly modifiable for participants (includes all the bullet logic) {
            $xx_v[5:0] = $reset ? 6'b0 : >>1$xx_v + m5_sign_extend($xx_a, 3, 2);
            $yy_v[5:0] = $reset ? 6'b0 : >>1$yy_v + m5_sign_extend($yy_a, 3, 2);
            `BOGUS_USE($xx_a[3:0] $yy_a[3:0])   /// A bug workaround.
            
            $xx_p[7:0] = $reset ? 8'd216 + #ship * 8'd40 :
                         $destroyed ? >>1$xx_p :
                         >>1$xx_p + m5_sign_extend($xx_v, 5, 2);
            $yy_p[7:0] = $reset ?
                            (#ship == 1) ? 8'd228 :
                            8'd208 :
                         $destroyed ? >>1$yy_p :
                         >>1$yy_p + m5_sign_extend($yy_v, 5, 2);
            
            
            
            /enemy_ship[m5_SHIP_RANGE]
               // Any bullet hit #enemy_ship.
               $hit = m5_repeat(m5_BULLET_CNT, ['/ship/bullet[m5_LoopCnt]/enemy_ship[#enemy_ship]$hit || '])1'b0;
            
            
            // Was shot by any enemy ship
            $shot = m5_repeat(m5_SHIP_CNT, ['/player[! /player$player_id]/ship[m5_LoopCnt]/enemy_ship[#ship]$hit || '])1'b0;
            // Destroyed from going out of bounds
            $out_of_bounds = $reset ? 1'b0 :
                   (>>1$xx_p >= 8'd128 && >>1$xx_p < (8'd192 + 8'd\m5_half_ship_width)) ||
                   (>>1$xx_p < 8'd128 && >>1$xx_p > (8'd64 - 8'd\m5_half_ship_width)) ||
                   (>>1$yy_p >= 8'd128 && >>1$yy_p < (8'd192 + 8'd\m5_half_ship_height)) ||
                   (>>1$yy_p < 8'd128 && >>1$yy_p > (8'd64 - 8'd\m5_half_ship_height));
            $hit = $shot || $out_of_bounds;
            $destroyed = $reset ? 1'b0 :
                    >>1$destroyed ? 1'b1 :
                    ($shot && !>>1$do_shield) ||
                    $out_of_bounds;
            
            
            
            
            // ||||||||||||||||  BULLET LOGIC ||||||||||||||||
            /bullet[2:0]
               $can_fire = (/ship$attempt_fire && !>>1$bullet_exists && !/ship$destroyed);
               $prev_found_fire = (#bullet == 0) ? 1'b0 : /bullet[#bullet - 1]$found_fire;
               $successful_fire = $can_fire && ! $prev_found_fire;
               $found_fire = $prev_found_fire || $successful_fire;
               
               $bullet_dir[1:0] = $successful_fire ? /ship$fire_dir : >>1$bullet_dir;
               
               
               $bullet_x[7:0] = $successful_fire ?
                                   ($bullet_dir == 2'b00) ? (/ship$xx_p + 8'd\m5_half_ship_width + 8'd\m5_half_bullet_height) :
                                   ($bullet_dir == 2'b10) ? (/ship$xx_p - 8'd\m5_half_ship_width - 8'd\m5_half_bullet_height) :
                                   /ship$xx_p :
                                ($bullet_dir == 2'b00) ? (>>1$bullet_x + 8'd\m5_bullet_height) :
                                ($bullet_dir == 2'b10) ? (>>1$bullet_x - 8'd\m5_bullet_height) :
                                >>1$bullet_x;
               $bullet_y[7:0] = $successful_fire ?
                                   ($bullet_dir == 2'b01) ? (/ship$yy_p - 8'd\m5_half_ship_height - 8'd\m5_half_bullet_height) :
                                   ($bullet_dir == 2'b11) ? (/ship$yy_p + 8'd\m5_half_ship_height + 8'd\m5_half_bullet_height) :
                                   /ship$yy_p :
                                ($bullet_dir == 2'b01) ? (>>1$bullet_y - 8'd\m5_bullet_height) :
                                ($bullet_dir == 2'b11) ? (>>1$bullet_y + 8'd\m5_bullet_height) :
                                >>1$bullet_y;
               
               
               /enemy_ship[m5_SHIP_RANGE]
                  $ANY = /player/other_player/ship[#enemy_ship]$ANY;
                  $hit = (/_top$reset || >>1$destroyed || ! /bullet>>1$bullet_exists) ? 1'b0 :
                         (/bullet>>1$bullet_dir[0] == 1'b1) ?
                            (((>>1$xx_p + 8'b10000000) > (- /bullet>>1$bullet_x + 8'b10000000 - (8'd\m5_half_ship_width + 8'd\m5_half_bullet_width))) &&
                             ((>>1$xx_p + 8'b10000000) < (- /bullet>>1$bullet_x + 8'b10000000 + (8'd\m5_half_ship_width + 8'd\m5_half_bullet_width))) &&
                             ((>>1$yy_p + 8'b10000000) > (- /bullet>>1$bullet_y + 8'b10000000 - (8'd\m5_half_ship_height + 8'd\m5_half_bullet_height))) &&
                             ((>>1$yy_p + 8'b10000000) < (- /bullet>>1$bullet_y + 8'b10000000 + (8'd\m5_half_ship_height + 8'd\m5_half_bullet_height)))
                            ) :
                            (((>>1$xx_p + 8'b10000000) > (- /bullet>>1$bullet_x + 8'b10000000 - (8'd\m5_half_ship_width + 8'd\m5_half_bullet_height))) &&
                             ((>>1$xx_p + 8'b10000000) < (- /bullet>>1$bullet_x + 8'b10000000 + (8'd\m5_half_ship_width + 8'd\m5_half_bullet_height))) &&
                             ((>>1$yy_p + 8'b10000000) > (- /bullet>>1$bullet_y + 8'b10000000 - (8'd\m5_half_ship_height + 8'd\m5_half_bullet_width))) &&
                             ((>>1$yy_p + 8'b10000000) < (- /bullet>>1$bullet_y + 8'b10000000 + (8'd\m5_half_ship_height + 8'd\m5_half_bullet_width))));
               $hit_an_enemy = | /enemy_ship[*]$hit;
               
               
               $bullet_exists = /_top$reset ? 1'b0 :
                                $hit_an_enemy ? 1'b0 :
                                (>>1$bullet_exists || $successful_fire) ?
                                   ($bullet_dir[0] == 1'b0) ?
                                      (($bullet_x < (8'd64 + 8'd\m5_half_bullet_height)) || ($bullet_x > (8'd192 - 8'd\m5_half_bullet_height))) &&
                                      (($bullet_y < (8'd64 + 8'd\m5_half_bullet_width)) || ($bullet_y > (8'd192 - 8'd\m5_half_bullet_width))) :
                                   (($bullet_y < (8'd64 + 8'd\m5_half_bullet_height)) || ($bullet_y > (8'd192 - 8'd\m5_half_bullet_height))) &&
                                   (($bullet_x < (8'd64 + 8'd\m5_half_bullet_width)) || ($bullet_x > (8'd192 - 8'd\m5_half_bullet_width))) :
                                1'b0;
               
               
               
               
               // ================  BULLET VIZ  ================
               \viz_js
                  box: { left: -128, top: -128, width: 256, height: 256, strokeWidth: 0 },
                  layout: { left: 0, top: 0 },
               
               
                  // ~~~~~~~~ Init ~~~~~~~~
                  init()
                  {
                     const player_id = (this.getIndex("player") == 1);
                     ret = {};
               
               
                     // Load Bullet Image:
                     ret.bullet_img = this.newImageFromURL(
                        (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/bullet_sprites/p2/smol_bullet.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/bullet_sprites/p1/smol_bullet.png"),
                        "",
                        { left: 0, top: 0,
                           width: 3, height: 10,
                           imageSmoothing: false }
                     );
                     ret.bullet_img.set({ originX: "center", originY: "center" });
               
               
                     // Create Bullet Rect:
                     ret.bullet_rect = new fabric.Rect({ width: 10, height: 2, strokeWidth: 0, fill: (player_id ? "#00ffb350" : "#ffff0050"), orginX: "center", originY: "center" });
                     ret.bullet_rect.set({ originX: "center", originY: "center" });
               
               
                     return ret;
                  },
               
               
                  // ######## Render ########
                  render()
                  {
                     const player_id = this.getIndex("player");
                     const ship_id = this.getIndex("ship");
               
                     function asSigned(val, bit_count) {
                        if (val >= 2**(bit_count - 1)) {
                           val -= 2**bit_count;
                        }
                        return val;
                     }
               
               
                     const forward = this.steppedBy() >= 0;
                     const step = forward ? -1 : 1;   // The offset (step) for the cycle from which to animate.
                     m5_get_sig(, successful_fire, Bool)
                     m5_get_sig(, bullet_exists, Bool)
                     ///m5_get_sig(, hit_an_enemy, Bool)
                     m5_get_sig(/ship[ship_id], xx_p, SignedInt)
                     m5_get_sig(/ship[ship_id], yy_p, SignedInt)
                     m5_get_sig(, bullet_x, SignedInt)
                     m5_get_sig(, bullet_y, SignedInt)
                     m5_get_sig(, bullet_dir, Int)
                     
                     const forwardFire = is_successful_fire && forward;
                     const backwardFire = was_successful_fire && ! forward
                     const left = backwardFire ? is_xx_p : is_bullet_x;
                     const top =  -(backwardFire ? is_yy_p : is_bullet_y);
                     // Animate bullet image:
                     this.obj.bullet_img.set({
                        visible: was_bullet_exists || is_bullet_exists,
                        opacity: was_bullet_exists ? 1 : 0,
                        left: forwardFire ? was_xx_p : was_bullet_x,
                        top:  -(forwardFire ? was_yy_p : was_bullet_y),
                        angle: ((forwardFire ? is_bullet_dir : was_bullet_dir) + 1) * 90,
                     }).animate({
                        opacity: is_bullet_exists ? 1 : 0,
                        left,
                        top,
                     }, {
                        duration: m5_default_anim_duration,
                        easing: fabric.util.ease.m5_default_anim_easing
                     }).thenSet({ visible: is_bullet_exists });
                     // Animate bullet rect similarly:
                     this.obj.bullet_rect.set({
                        visible: this.obj.bullet_img.visible,
                        opacity: this.obj.bullet_img.opacity,
                        left: this.obj.bullet_img.left,
                        top: this.obj.bullet_img.top,
                        angle: this.obj.bullet_img.angle - 90
                     }).animate({
                        opacity: is_bullet_exists ? 1 : 0,
                        left,
                        top,
                     }, {
                        duration: m5_default_anim_duration,
                        easing: fabric.util.ease.m5_default_anim_easing
                     }).thenSet({ visible: is_bullet_exists });
                  }
            
            
            
            
            
            // =====================   SHIP VIZ   =====================
            
            \viz_js
               box: { left: -128, top: -128, width: 256, height: 256, strokeWidth: 0 },
               layout: { left: 0, top: 0 },
            
            
               // ~~~~~~~~ Init ~~~~~~~~
               init() {
                  let ret = {};
                  const player_id = (this.getIndex("player") == 1);
            
            
                  // Load Ship Images:
                  ret.ship_sprite0_img = this.newImageFromURL(
                     (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/smol_ship0.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/smol_ship0.png"),
                     "",
                     { left: 0, top: 0,
                        width: 11, height: 15,
                        imageSmoothing: false }
                  );
                  ret.ship_sprite0_img.set({ originX: "center", originY: "center" });
            
                  ret.ship_sprite1_img = this.newImageFromURL(
                     (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/smol_ship1.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/smol_ship1.png"),
                     "",
                     { left: 0, top: 0,
                        width: 11, height: 15,
                        imageSmoothing: false }
                  );
                  ret.ship_sprite1_img.set({ originX: "center", originY: "center" });
            
                  ret.ship_sprite2_img = this.newImageFromURL(
                     (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/smol_ship2.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/smol_ship2.png"),
                     "",
                     { left: 0, top: 0,
                        width: 11, height: 15,
                        imageSmoothing: false }
                  );
                  ret.ship_sprite2_img.set({ originX: "center", originY: "center" });
            
                  ret.ship_sprite3_img = this.newImageFromURL(
                     (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/smol_ship3.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/smol_ship3.png"),
                     "",
                     { left: 0, top: 0,
                        width: 11, height: 15,
                        imageSmoothing: false }
                  );
                  ret.ship_sprite3_img.set({ originX: "center", originY: "center" });
            
            
                  // Load Shield Image:
                  ret.shield_img = this.newImageFromURL(
                     "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/shield.png",
                     "",
                     { left: 0, top: 0,
                        width: 23, height: 23,
                        angle: player_id ? 180.0 : 0.0,
                        imageSmoothing: false }
                  );
                  ret.shield_img.set({ originX: "center", originY: "center" });
            
            
                  // Create Shield Meter:
                  ret.shield_meter_back = new fabric.Rect({ width: 10, height: 1.5, strokeWidth: 0, fill: "#b0b0b0ff", originX: "left", originY: "center", angle: player_id ? 180.0 : 0.0 });
                  ret.shield_meter = new fabric.Rect({ width: 10, height: 1.5, strokeWidth: 0, fill: "#17f7ffff", originX: "left", originY: "center", angle: player_id ? 180.0 : 0.0 });
            
            
            
            
                  // Create Ship Rect:
                  ret.ship_rect = new fabric.Rect({ width: 8, height: 8, strokeWidth: 0, fill: (player_id ? "#00ffb350" : "#ffff0050"), originX: "center", originY: "center" });
            
            
            
            
                  // Load Explosion Images:
                  ret.explody_sprite0 = this.newImageFromURL(
                     player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p2/explody0.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p1/explody0.png",
                     "",
                     { left: 0, top: 0,
                        width: 28, height: 28,
                        imageSmoothing: false,
            
                        // Adjust angle so that even when the ships flip, the explosion still faces the same direction.
                        angle: player_id ? 180 : 0 }
                  );
                  ret.explody_sprite0.set({ originX: "center", originY: "center", visible: false });
            
                  ret.explody_sprite1 = this.newImageFromURL(
                     player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p2/explody1.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p1/explody1.png",
                     "",
                     { left: 0, top: 0,
                        width: 28, height: 28,
                        imageSmoothing: false,
            
                        // Adjust angle so that even when the ships flip, the explosion still faces the same direction.
                        angle: player_id ? 180 : 0 }
                  );
                  ret.explody_sprite1.set({ originX: "center", originY: "center", visible: false });
            
                  ret.explody_sprite2 = this.newImageFromURL(
                     player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p2/explody2.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p1/explody2.png",
                     "",
                     {
                        left: 0, top: 0,
                        width: 28, height: 28,
                        imageSmoothing: false,
            
                        // Adjust angle so that even when the ships flip, the explosion still faces the same direction.
                        angle: player_id ? 180 : 0 }
                  );
                  ret.explody_sprite2.set({ originX: "center", originY: "center", visible: false });
            
                  ret.explody_sprite3 = this.newImageFromURL(
                     player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p2/explody3.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p1/explody3.png",
                     "",
                     { left: 0, top: 0,
                        width: 28, height: 28,
                        imageSmoothing: false,
            
                        // Adjust angle so that even when the ships flip, the explosion still faces the same direction.
                        angle: player_id ? 180 : 0 }
                  );
                  ret.explody_sprite3.set({ originX: "center", originY: "center", visible: false });
            
                  ret.explody_sprite4 = this.newImageFromURL(
                     player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p2/explody4.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/explosion_sprites/p1/explody4.png",
                     "",
                     { left: 0, top: 0,
                        width: 28, height: 28,
                        imageSmoothing: false,
            
                        // Adjust angle so that even when the ships flip, the explosion still faces the same direction.
                        angle: player_id ? 180 : 0 }
                  );
                  ret.explody_sprite4.set({ originX: "center", originY: "center", visible: false });
            
                  return ret;
               },
            
            
            
            
               // ######## Render ########
               render() {
                  let player_id = this.getIndex("player");
                  let ship_id = this.getIndex();
            
                  function asSigned(val, bit_count) {
                     if (val >= 2**(bit_count - 1)) {
                        val -= 2**bit_count;
                     }
                     return val;
                  }
            
                  let pseudo_this = this;
                  function setExplosionFrame(frame_num) {
                     pseudo_this.obj.explody_sprite0.set({visible: frame_num == 0});
                     pseudo_this.obj.explody_sprite1.set({visible: frame_num == 1});
                     pseudo_this.obj.explody_sprite2.set({visible: frame_num == 2});
                     pseudo_this.obj.explody_sprite3.set({visible: frame_num == 3});
                     pseudo_this.obj.explody_sprite4.set({visible: frame_num == 4});
                  }
            
            
                  // Select Current Ship Image:
                  let current_ship_img;
                  let accel_mag = ((asSigned('$xx_a'.asInt(), 4) ** 2) + (asSigned('$yy_a'.asInt(), 4) ** 2)) ** 0.5;
                  if (accel_mag == 0)
                  {
                     current_ship_img = this.obj.ship_sprite0_img;
                     this.obj.ship_sprite1_img.set({ visible: false });
                     this.obj.ship_sprite2_img.set({ visible: false });
                     this.obj.ship_sprite3_img.set({ visible: false });
                  }
                  else if (accel_mag < 1.75)
                  {
                     current_ship_img = this.obj.ship_sprite1_img;
                     this.obj.ship_sprite0_img.set({ visible: false });
                     this.obj.ship_sprite2_img.set({ visible: false });
                     this.obj.ship_sprite3_img.set({ visible: false });
                  }
                  else if (accel_mag < 5)
                  {
                     current_ship_img = this.obj.ship_sprite2_img;
                     this.obj.ship_sprite0_img.set({ visible: false });
                     this.obj.ship_sprite1_img.set({ visible: false });
                     this.obj.ship_sprite3_img.set({ visible: false });
                  }
                  else
                  {
                     current_ship_img = this.obj.ship_sprite3_img;
                     this.obj.ship_sprite0_img.set({ visible: false });
                     this.obj.ship_sprite1_img.set({ visible: false });
                     this.obj.ship_sprite2_img.set({ visible: false });
                  }
            
                  const step = this.steppedBy() >= 0 ? -1 : 1;   // The offset (step) for the cycle from which to animate.
                  m5_get_sig(, xx_p, SignedInt)
                  m5_get_sig(, yy_p, SignedInt)
                  
                  const energy_meter_x_offset = player_id ? 5 : -5;
                  const energy_meter_y_offset = player_id ? -9 : 9;
            
                  const energy_last_meter = '>>1$Energy'.asInt();
                  const energy_meter = '$Energy'.asInt();
                  const energy_next_meter = '$Energy'.step().asInt();
            
            
                  // If Moving Forward Cycles:
                  if (this.steppedBy() >= 0)
                  {
                     // Determine the correct starting and ending angles for the ship for this cycle
                     let cycle_xx_a = '>>1$xx_a';
                     let cycle_yy_a = '>>1$yy_a';
                     while ((cycle_xx_a != unassigned) && (cycle_xx_a.asInt() == 0) && (cycle_yy_a.asInt() == 0))
                     {
                        cycle_xx_a.step(-1);
                        cycle_yy_a.step(-1);
                     }
                     let set_angle = -(Math.atan2(asSigned(cycle_yy_a.asInt(), 4), asSigned(cycle_xx_a.asInt(), 4)) * 180 / Math.PI) + 90;
                     let animate_angle;
                     if (('$xx_a'.asInt() == 0) && ('$yy_a'.asInt() == 0))
                     {
                        animate_angle = set_angle;
                     }
                     else
                     {
                        animate_angle = -(Math.atan2(asSigned('$yy_a'.asInt(), 4), asSigned('$xx_a'.asInt(), 4)) * 180 / Math.PI) + 90;
                     }
            
            
                     // Set ship image:
                     current_ship_img.set({
                        left: asSigned('>>1$xx_p'.asInt(), 8),
                        top: -asSigned('>>1$yy_p'.asInt(), 8),
                        angle: set_angle,
                        visible: !'$destroyed'.asBool()
                     });
            
                     // Set ship rect:
                     this.obj.ship_rect.set({
                        left: current_ship_img.left,
                        top: current_ship_img.top,
                        visible: current_ship_img.visible
                     });
                     
                     // Set shield meter:
                     this.obj.shield_meter_back.set({
                        left: current_ship_img.left + energy_meter_x_offset,
                        top: current_ship_img.top + energy_meter_y_offset,
                        visible: current_ship_img.visible
                     });
                     this.obj.shield_meter.set({
                        left: current_ship_img.left + energy_meter_x_offset,
                        top: current_ship_img.top + energy_meter_y_offset,
                        scaleX: energy_last_meter / m5_max_energy,
                        fill: "#12e32e",
                        visible: current_ship_img.visible
                     });
                     
                     // Set shield:
                     this.obj.shield_img.set({
                        left: current_ship_img.left,
                        top: current_ship_img.top,
                        scaleX: '>>1$do_shield'.asBool() ? 1.0 : 0.0,
                        scaleY: '>>1$do_shield'.asBool() ? 1.0 : 0.0,
                        visible: ('$do_shield'.asBool() || '>>1$do_shield'.asBool()) && !'$destroyed'.asBool(),
                        opacity: 1.0
                     });
            
                     // Animate ship image:
                     let animateShip = current_ship_img.animate({
                        left: is_xx_p,
                        top: -is_yy_p,
                        angle: animate_angle,
                     }, {
                        duration: m5_default_anim_duration,
                        easing: fabric.util.ease.m5_default_anim_easing
                        }
                     );
            
                     // Animate explosion if applicable:
                     if ('$destroyed'.asBool() && !'>>1$destroyed'.asBool())
                     {
                        for (let i = 0; i < 5; i++)
                        {
                           this.obj[`explody_sprite${i}`]
                              .set({visible: false})
                              .wait(i * 140)
                              .thenSet({left: is_xx_p, top: -is_yy_p, visible: true})
                              .thenWait(140).thenSet({visible: false});
                        }
                     }
                     else
                     {
                        for (let i = 0; i < 5; i++)
                        {
                           this.obj[`explody_sprite${i}`].set({visible: false});
                        }
                     }
            
            
                     // Animate ship rect:
                     this.obj.ship_rect.animate({
                        left: is_xx_p,
                        top: -is_yy_p,
                     }, {
                        duration: m5_default_anim_duration,
                        onComplete: () => {this.obj.ship_rect.set({ visible: !'$destroyed'.asBool()})},
                        easing: fabric.util.ease.m5_default_anim_easing
                     });
            
                     // Animate shield meter:
                     this.obj.shield_meter_back.animate({
                        left: is_xx_p + energy_meter_x_offset,
                        top: -is_yy_p + energy_meter_y_offset,
                     }, {
                        duration: m5_default_anim_duration,
                        onComplete: () => {this.obj.shield_meter_back.set({ visible: !'$destroyed'.asBool()})},
                        easing: fabric.util.ease.m5_default_anim_easing
                     });
                     this.obj.shield_meter.animate({
                        left: is_xx_p + energy_meter_x_offset,
                        top: -is_yy_p + energy_meter_y_offset,
                        scaleX: energy_meter / m5_max_energy,
                     }, {
                        duration: m5_default_anim_duration,
                        onComplete: () => {this.obj.shield_meter.set({ visible: !'$destroyed'.asBool() })},
                        easing: fabric.util.ease.m5_default_anim_easing
                     });
            
                     // Animate shield:
                     this.obj.shield_img.animate({
                        left: is_xx_p,
                        top: -is_yy_p,
                        scaleX: '$do_shield'.asBool() ? 1.0 :
                                '$shot'.asBool() ? 2.0 : 0.0,
                        scaleY: '$do_shield'.asBool() ? 1.0 :
                                '$shot'.asBool() ? 2.0 : 0.0,
                        opacity: '$shot'.asBool() ? 0.0 : 1.0
                     }, {
                        duration: m5_default_anim_duration,
                        easing: fabric.util.ease.m5_default_anim_easing
                     }).thenSet({ visible: !'$destroyed'.asBool() && this.obj.shield_img.visible })
                  }
            
            
                  // If Moving Backward Cycles:
                  else
                  {
                     // Determine the correct starting and ending angles for the ship this cycle
                     let cycle_xx_a = '$xx_a';
                     let cycle_yy_a = '$yy_a';
                     while ((cycle_xx_a != unassigned) && (cycle_xx_a.asInt() == 0) && (cycle_yy_a.asInt() == 0))
                     {
                        cycle_xx_a.step(-1);
                        cycle_yy_a.step(-1);
                     }
                     let animate_angle = -(Math.atan2(asSigned(cycle_yy_a.asInt(), 4), asSigned(cycle_xx_a.asInt(), 4)) * 180 / Math.PI) + 90;
            
                     let set_angle;
                     if (('$xx_a'.step().asInt() == 0) && ('$yy_a'.step().asInt() == 0))
                     {
                        set_angle = animate_angle;
                     }
                     else
                     {
                        set_angle = -(Math.atan2(asSigned('$yy_a'.step().asInt(), 4), asSigned('$xx_a'.step().asInt(), 4)) * 180 / Math.PI) + 90;
                     }
            
            
                     // Animate explosion if applicable:
                     if ('$destroyed'.step().asBool() && !'$destroyed'.asBool())
                     {
                        for (let i = 0; i < 5; i++)
                        {
                           this.obj[`explody_sprite${4 - i}`]
                              .set({visible: false})
                              .wait(i * 140)
                              .thenSet({left: is_xx_p, top: -is_yy_p, visible: true})
                              .thenWait(140).thenSet({visible: false});
                        }
            
                        current_ship_img.wait(560).thenSet({visible: true});
                        this.obj.ship_rect.wait(560).thenSet({visible: true});
                     }
                     else
                     {
                        for (let i = 0; i < 5; i++)
                        {
                           this.obj[`explody_sprite${i}`].set({visible: false});
                        }
                     }
            
            
                     let next_xx_p = asSigned('$xx_p'.step().asInt(), 8);
                     let next_yy_p = -asSigned('$yy_p'.step().asInt(), 8);
            
                     // Set ship image:
                     current_ship_img.set({
                        left: next_xx_p,
                        top: next_yy_p,
                        angle: set_angle,
                        visible: !'$destroyed'.step().asBool()
                     });
            
                     // Set ship rect:
                     this.obj.ship_rect.set({
                        left: current_ship_img.left,
                        top: current_ship_img.top,
                        visible: current_ship_img.visible
                     });
            
                     // Set shield meter:
                     this.obj.shield_meter_back.set({
                        left: current_ship_img.left + energy_meter_x_offset,
                        top: current_ship_img.top + energy_meter_y_offset,
                        visible: current_ship_img.visible
                     });
                     this.obj.shield_meter.set({
                        left: current_ship_img.left + energy_meter_x_offset,
                        top: current_ship_img.top + energy_meter_y_offset,
                        scaleX: energy_next_meter / m5_max_energy,
                        fill: "#12e32e",
                        visible: current_ship_img.visible
                     });
            
                     // Set shield:
                     this.obj.shield_img.set({
                        left: current_ship_img.left,
                        top: current_ship_img.top,
                        scaleX: '$do_shield'.step().asBool() ? 1.0 :
                                '$hit'.step().asBool() ? 2.0 :
                                0.0,
                        scaleY: '$do_shield'.step().asBool() ? 1.0 :
                                '$hit'.step().asBool() ? 2.0 :
                                0.0,
                        visible: ('$do_shield'.asBool() || '$do_shield'.step().asBool()) && !'$destroyed'.step().asBool(),
                        opacity: '$hit'.step().asBool() ? 0.0 : 1.0
                     });
            
            
            
                     // Animate ship image:
                     current_ship_img.animate({
                        left: is_xx_p,
                        top: -is_yy_p,
                        angle: animate_angle,
                     }, {
                        duration: m5_default_anim_duration,
                        easing: fabric.util.ease.m5_default_anim_easing
                     });
            
                     // Animate ship rect:
                     this.obj.ship_rect.animate({
                        left: is_xx_p,
                        top: -is_yy_p,
                     }, {
                        duration: m5_default_anim_duration,
                        easing: fabric.util.ease.m5_default_anim_easing
                     });
            
                     // Animate shield meter:
                     this.obj.shield_meter_back.animate({
                        left: is_xx_p + energy_meter_x_offset,
                        top: -is_yy_p + energy_meter_y_offset,
                     }, {
                        duration: m5_default_anim_duration,
                        onComplete: () => {this.obj.shield_meter_back.set({ visible: !'$destroyed'.asBool()})},
                        easing: fabric.util.ease.m5_default_anim_easing
                     });
                     this.obj.shield_meter.animate({
                        left: is_xx_p + energy_meter_x_offset,
                        top: -is_yy_p + energy_meter_y_offset,
                        scaleX: energy_meter / m5_max_energy,
                     }, {
                        duration: m5_default_anim_duration,
                        onComplete: () => {this.obj.shield_meter.set({ visible: !'$destroyed'.asBool() })},
                        easing: fabric.util.ease.m5_default_anim_easing
                     });
            
                     // Animate shield:
                     this.obj.shield_img.animate({
                        left: is_xx_p,
                        top: -is_yy_p,
                        scaleX: '$do_shield'.asBool() ? 1.0 : 0.0,
                        scaleY: '$do_shield'.asBool() ? 1.0 : 0.0,
                        opacity: 1.0,
                     }, {
                        duration: m5_default_anim_duration,
                        onComplete: () => {this.obj.shield_img.set({ visible: '$do_shield'.asBool() && !'$destroyed'.asBool()})},
                        easing: fabric.util.ease.m5_default_anim_easing
                     });
                  }
               }
      
      
      
      
      /background
         // ================  FOREGROUND VIZ  ================
         \viz_js
            name: "foreground",
            box: { left: -128, top: -128, width: 256, height: 256, strokeWidth: 0 },
            
         
            // ~~~~~~~~ Init ~~~~~~~~
            init()
            {
               let ret = {};
         
               // Load End Screens:
               ret.p1win_img = this.newImageFromURL(
                  "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/end_screens/p1win.png",
                  "",
                  { originX: "center",
                     left: 0, top: 0,
                     width: 108, height: 100,
                     imageSmoothing: false,
                     visible: true }
               );
               ret.p1win_img.set({visible: false});
         
               ret.p2win_img = this.newImageFromURL(
                  "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/end_screens/p2win.png",
                  "",
                  { originX: "center",
                     left: 0, top: 0,
                     width: 108, height: 100,
                     imageSmoothing: false,
                     visible: true }
               );
               ret.p2win_img.set({visible: false});
         
               ret.tie_img = this.newImageFromURL(
                  "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/end_screens/tie.png",
                  "",
                  { originX: "center",
                     left: 0, top: 0,
                     width: 108, height: 100,
                     imageSmoothing: false,
                     visible: true }
               );
               ret.tie_img.set({visible: false});
         
         
               // Create Background Masking Rects:
               ret.mask0 = new fabric.Rect({ left: 96, top: 0, width: 64, height: 256, strokeWidth: 0, fill: "#ffffffff", originX: "center", originY: "center" });
               ret.mask1 = new fabric.Rect({ left: 0, top: 96, width: 256, height: 64, strokeWidth: 0, fill: "#ffffffff", originX: "center", originY: "center" });
               ret.mask2 = new fabric.Rect({ left: -96, top: 0, width: 64, height: 256, strokeWidth: 0, fill: "#ffffffff", originX: "center", originY: "center" });
               ret.mask3 = new fabric.Rect({ left: 0, top: -128, width: 256, height: 128, strokeWidth: 0, fill: "#ffffffff", originX: "center", originY: "center" });
         
         
               // Load Picture Frame:
               ret.frame_img = this.newImageFromURL(
                  "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/gold_picture_frame.png",
                  "",
                  { originX: "center", originY: "center",
                     left: 0, top: 0,
                     width: 190, height: 190,
                     imageSmoothing: false }
               );
         
               return ret;
            },
         
         
            // ######## Render ########
            render()
            {
               // Nothing shown by default.
               this.obj.p1win_img.set({visible: false});
               this.obj.p2win_img.set({visible: false});
               this.obj.tie_img.set({visible: false});
              
               const forward = this.steppedBy() >= 0;
               const step = forward ? -1 : 1;   // The offset (step) for the cycle from which to animate.
               m5_get_sig(/_secret>>1, win_id, Int)
               const animate = is_win_id != was_win_id;
               const win_id = forward ? is_win_id : was_win_id;
               const endScreen =
                      (win_id == 1) ? this.obj.p1win_img :
                      (win_id == 2) ? this.obj.p2win_img :
                                      this.obj.tie_img;
               // Animate Y coords.
               const up = -164;
               const down = -64;
               console.log(`steppedBy: ${this.steppedBy()}, is_win_id: ${is_win_id}, was_win_id: ${was_win_id}, win_id: ${win_id}`);
               if (animate || win_id != 0) {
                  endScreen.set({visible: true, top: (animate && forward) ? up : down});
                  if (animate) {
                     endScreen.animate({
                        top: forward ? down : up,
                     }, {
                        duration: 1000,
                        easing: fabric.util.ease.easeOutCubic
                     });
                  } else if (win_id != 0) {
                     endScreen.set({visible: true, top: -64});
                  }
               }
            }
            
      // ==================== Placard =================
      m5_var(placard_p0_len, m5_length(m5_get_ago(team_name, 0)))
      m5_var(placard_p1_len, m5_length(m5_get_ago(team_name, 1)))
      m5_var(placard_len, m5_if(m5_placard_p0_len < m5_placard_p1_len, m5_placard_p1_len, m5_placard_p0_len))
      m5_var(placard_width, m5_calc((m5_placard_len + 12) * 4))
      /placard
         // The "placard" showing team names.
         \viz_js
            box: { width: m5_placard_width, height: 19, left: -m5_calc(m5_placard_width / 2), fill: "#dbc077", stroke: "#504020", strokeWidth: 0.5 },
            lib: {
               pixelFont: "Press Start 2P"
            },
            init () {
               // Load pixelated font.
               const pixelFont = {
                  Silkscreen: "https://fonts.gstatic.com/s/silkscreen/v4/m8JXjfVPf62XiF7kO-i9YLNlaw.woff2",
                  "Pixelify Sans": "https://fonts.gstatic.com/s/pixelifysans/v1/CHy2V-3HFUT7aC4iv1TxGDR9DHEserHN25py2TTp0E1fZZM.woff2",
                  "Press Start 2P": "https://fonts.gstatic.com/s/pressstart2p/v15/e3t4euO8T-267oIAQAu6jDQyK3nVivM.woff2",
               };
               const font = new FontFace('/placard'.pixelFont, `url(${pixelFont[ '/placard'.pixelFont]})`);
               font.load().then((loadedFont) => {
                  // Add the font to the document
                  document.fonts.add(loadedFont);
                  this.getCanvas().renderAll();
               });
            },
            where: { left: -m5_calc(m5_placard_width / 2), top: 110, height: 20, scale: 1 }
         /player[1:0]
            \viz_js
               box: { width: m5_placard_width, height: 20, left: -m5_calc(m5_placard_width / 2), strokeWidth: 0 },
               layout: {top: 7},
               init() {
                  const fontWidthCorrection = {
                     Silkscreen: 1.39,
                     "Pixelify Sans": 1.075,
                     "Press Start 2P": 2.37,
                  };
                  
                  let p = this.getIndex();
                  let playerLabel = (fill, offset) => {
                     ret = new fabric.Text(
                                `  ${p ? "Green: m5_get_ago(team_name, 0)" : "Yellow: m5_get_ago(team_name, 1)"}  `,
                                { left: offset, top: offset,
                                  fontFamily: '/placard'.pixelFont, fontSize: "5", fontWeight: 400,
                                  originX: "center",
                                  fill
                                }
                            );
                     ret.set({left: -ret.width * (fontWidthCorrection[ '/placard'.pixelFont] - 1) / 2});
                     return ret;
                  };
                  ret = {
                     //shine: playerLabel("#ffefc0", 0.15),
                     label: playerLabel("#504020", 0),
                  };
                  /* */
                  ret.test =
                     new fabric.Rect({
                          left: ret.label.left,
                          top: ret.label.top,
                          width: ret.label.width,
                          height: ret.label.height,
                          originX: ret.label.originX,
                          originY: ret.label.originY,
                          fill: "rgba(255, 0, 0, 0.2)"
                     });
                  /* */
                  return ret;
               },
               where: {left: -m5_calc(m5_placard_width / 2), top: 2.7},
      
      
      // Assert these to end simulation (before Makerchip cycle limit).
      $passed = (| /player[*]>>3$lost) && !>>1$reset;
      $failed = *cyc_cnt > 600;




\SV
   m5_makerchip_module
\TLV
   // Define teams.
   ///m5_team(random, Random 1)
   m5_team(random, Random 2)
   ///m5_team(sitting_duck, Sitting Duck)
   m5_team(test1, Test 1)
   
   // Instantiate the Showdown environment.
   m5+showdown(/top, /secret)
   
   *passed = /secret$passed;
   *failed = /secret$failed;
\SV
   endmodule
