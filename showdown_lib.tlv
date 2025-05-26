\m5_TLV_version 1d: tl-x.org
\m5
   / The First Annual Makerchip ASIC Showdown, Summer 2025: Space Battle
   / This file is the library providing the content.
   / See the repo's README.md for more information.
   use(m5-1.0)
   
   fn(team_tlv_url, ?TlvFile, {
      ~if_eq(m5_TlvFile, [''], [
         / Use default "random" opponent.
         var(github_id, random)
      ], [
         / Include submitted TLV URL, reporting an error if it produces text output.
         if_null(m4_include_lib(_team1_lib), [
            error(['The following TL-Verilog library produced output text. Ignoring']m5_nl    m5_TlvFile)
         ])
      ])
      on_return(var, github_id, m5_github_id)   /// Preserve what the library defined after it gets popped by the return.
   })
   
   
   define_hier(SHIP, 2, 0)
   define_hier(BULLET, 3, 0)
   
   // Verilog sign extend.
   macro(sign_extend, ['{{$3{$1[$2]}}, $1}'])

// /-------------------------------------------+-------------------------------------------\
// |                                                                                       |
// |      Your job is to write logic to pilot your ships to destroy the enemy ships!       |
// |                                                                                       |
// |                                                                                       |
// |   You can define the following signals:                                               |
// |   - $xx_a: ship's x-axis acceleration                                                 |
// |   - $yy_a: ship's y_axis acceleration                                                 |
// |   - $attempt_shield: activate ship's shield if not on cooldown (The shield cools      |
// |   down for 4 cycles, charges up for 10, and stays active depending on how long it     |
// |   was changed up for)                                                                 |
// |   - $attempt_fire: fire one of the ship's bullets if one is available (each ship      |
// |   can have 3 bullets on screen at once)                                               |
// |   - $fire_dir: the direction in which the ship fires its bullet                       |
// |                                                                                       |
// |   Additional information:                                                             |
// |   - Ship dimensions are 10x10                                                         |
// |   - Bullet dimensions are 2x16                                                        |
// |   - Bullets move 16 tiles per cycle                                                   |
// |                                       Good luck!                                      |
// |                                                                                       |
// \-------------------------------------------+-------------------------------------------/

// Team logic providing random behavior.
\TLV team_random()
   /ship[*]
      ///m4_rand($rand, 31, 0)
      $attempt_fire = 1'b1;


\TLV team_logic(/_top, /_name, /_showdown, _team_num)
   /_name
      /m5_SHIP_HIER    // So team code can use /ship[*].
         $reset = /_top$reset;
         `BOGUS_USE($reset)
      m5+call(team_\m5_get_ago(github_id, _team_num))

\TLV showdown(/_top, /_showdown, _hidden)
   /// Each team submits a file containing a TLV macro whose name is the GitHub ID matching the
   /// repository and the submission (omitting unsupported characters, like '-'), as:
   /// var(github_id, xxx)
   /// \TLV team_xxx()
   ///    ...
   
   /// Make sure both teams defined their github_id.
   m5_if_neq(m5_depth_of(github_id), 2, ['m5_error(['A team failed to define github_id.'])'])
   
   m5+team_logic(/_top, /team0_['']_hidden, /_showdown['']_['']_hidden, 0)
   m5+team_logic(/_top, /team1_['']_hidden, /_showdown['']_['']_hidden, 1)
   
   /_showdown['']_['']_hidden
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
            
            // Control inputs {
            $ANY = /player$player_id ? /_top/team1_['']_hidden/ship$ANY : /_top/team0_['']_hidden/ship$ANY;
            
            $xx_a[3:0] = >>1$reset ? 4'd5 :
               ((>>1$xx_p + 8'b10000000) > (8'd32 + 8'b10000000)) ? 4'b1111 :
               ((>>1$xx_p + 8'b10000000) < (- 8'd32 + 8'b10000000)) ? 4'b1 :
               4'b0;
            
            
            $yy_a[3:0] = /top>>1$reset ? 4'b1 :
               ((>>1$yy_p + 8'b10000000) > (- 8'd12 + 8'b10000000)) ? 4'b1111 :
               ((>>1$yy_p + 8'b10000000) < (- 8'd48 + 8'b10000000)) ? 4'b1 :
               4'b0;
            
            
            //$attempt_fire = 1'b1;
            $fire_dir[1:0] = 2'b11; //0 = right, 1 = down, 2 = left, 3 = up
            
            
            $attempt_shield = /top>>1$reset ? 1'b0 :
                              >>1$shield_counter == 8'd0;
            // }
            
            // Is accessable, but not directly modifiable for participants (includes all the bullet logic) {
            $xx_v[5:0] = /top$reset ? 6'b0 : >>1$xx_v + m5_sign_extend($xx_a, 3, 2);
            $yy_v[5:0] = /top$reset ? 6'b0 : >>1$yy_v + m5_sign_extend($yy_a, 3, 2);
            
            
            $xx_p[7:0] = /top$reset ?
                            (#ship == 0) ? 8'd224 :
                            8'd32 :
                         $destroyed ? >>1$xx_p :
                         >>1$xx_p + m5_sign_extend($xx_v, 5, 2);
            $yy_p[7:0] = /top$reset ? 8'd208 :
                         $destroyed ? >>1$yy_p :
                         >>1$yy_p + m5_sign_extend($yy_v, 5, 2);
            
            
            $successful_shield = $attempt_shield && !$destroyed;
            $shield_counter[8:0] = /top>>1$reset ? 8'd14 :
                                   $hit ? 8'd14 :
                                   >>1$shield_counter == 8'd0 ?
                                      $successful_shield ? 8'd20 : 8'b0 :
                                   >>1$shield_counter <= 8'd10 ?
                                      $successful_shield ? 8'd14 + ((8'd12 - >>1$shield_counter) / 8'd2) :
                                      >>1$shield_counter - 1 :
                                   >>1$shield_counter - 1;
            $shield_up = $shield_counter > 8'd14;
            
            
            /enemy_ship[m5_SHIP_RANGE]
               // Any bullet hit #enemy_ship.
               $hit = m5_repeat(m5_BULLET_CNT, ['/ship/bullet[m5_LoopCnt]/enemy_ship[#enemy_ship]$hit || '])1'b0;
            
            
            // Was shot by any enemy ship
            $shot = m5_repeat(m5_SHIP_CNT, ['/player[! /player$player_id]/ship[m5_LoopCnt]/enemy_ship[#ship]$hit || '])1'b0;
            // Destroyed from going out of bounds
            $out_of_bounds = $reset ? 1'b0 :
                   (>>1$xx_p >= 8'd128 && >>1$xx_p < 8'd197) ||
                   (>>1$xx_p < 8'd128 && >>1$xx_p > 8'd59) ||
                   (>>1$yy_p >= 8'd128 && >>1$yy_p < 8'd197) ||
                   (>>1$yy_p < 8'd128 && >>1$yy_p > 8'd59);
            $hit = $shot || $out_of_bounds;
            $destroyed = /top$reset ? 1'b0 :
                    >>1$destroyed ? 1'b1 :
                    ($shot && !>>1$shield_up) ||
                    $out_of_bounds;
            
            
            
            
            // ||||||||||||||||  BULLET LOGIC ||||||||||||||||
            /bullet[2:0]
               $can_fire = (/ship$attempt_fire && !>>1$bullet_exists && !/ship$destroyed);
               $prev_found_fire = (#bullet == 0) ? 1'b0 : /bullet[#bullet - 1]$found_fire;
               $successful_fire = $can_fire && ! $prev_found_fire;
               $found_fire = $prev_found_fire || $successful_fire;
               
               $bullet_dir[1:0] = $successful_fire ? /ship$fire_dir : >>1$bullet_dir;
               
               
               $bullet_x[7:0] = $successful_fire ?
                                   ($bullet_dir == 2'b00) ? (/ship$xx_p + 8'd13) :
                                   ($bullet_dir == 2'b10) ? (/ship$xx_p - 8'd13) :
                                   /ship$xx_p :
                                ($bullet_dir == 2'b00) ? (>>1$bullet_x + 8'd16) :
                                ($bullet_dir == 2'b10) ? (>>1$bullet_x - 8'd16) :
                                >>1$bullet_x;
               $bullet_y[7:0] = $successful_fire ?
                                   ($bullet_dir == 2'b01) ? (/ship$yy_p - 8'd13) :
                                   ($bullet_dir == 2'b11) ? (/ship$yy_p + 8'd13) :
                                   /ship$yy_p :
                                ($bullet_dir == 2'b01) ? (>>1$bullet_y - 8'd16) :
                                ($bullet_dir == 2'b11) ? (>>1$bullet_y + 8'd16) :
                                >>1$bullet_y;
               
               
               /enemy_ship[m5_SHIP_RANGE]
                  $ANY = /player/other_player/ship[#enemy_ship]$ANY;
                  $hit = (/_top$reset || >>1$destroyed || ! /bullet>>1$bullet_exists) ? 1'b0 :
                         (/bullet>>1$bullet_dir[0] == 1'b1) ?
                            (((>>1$xx_p + 8'b10000000) > (- /bullet>>1$bullet_x + 8'b10000000 - 8'd6)) &&
                             ((>>1$xx_p + 8'b10000000) < (- /bullet>>1$bullet_x + 8'b10000000 + 8'd6)) &&
                             ((>>1$yy_p + 8'b10000000) > (- /bullet>>1$bullet_y + 8'b10000000 - 8'd13)) &&
                             ((>>1$yy_p + 8'b10000000) < (- /bullet>>1$bullet_y + 8'b10000000 + 8'd13))
                            ) :
                            (((>>1$xx_p + 8'b10000000) > (- /bullet>>1$bullet_x + 8'b10000000 - 8'd13)) &&
                             ((>>1$xx_p + 8'b10000000) < (- /bullet>>1$bullet_x + 8'b10000000 + 8'd13)) &&
                             ((>>1$yy_p + 8'b10000000) > (- /bullet>>1$bullet_y + 8'b10000000 - 8'd6)) &&
                             ((>>1$yy_p + 8'b10000000) < (- /bullet>>1$bullet_y + 8'b10000000 + 8'd6)));
               $hit_an_enemy = | /enemy_ship[*]$hit;
               
               
               $bullet_exists = /top$reset ? 1'b0 :
                                $hit_an_enemy ? 1'b0 :
                                (>>1$bullet_exists || $successful_fire) ?
                                   ($bullet_dir[0] == 1'b0) ?
                                      (($bullet_x < 8'd70) || ($bullet_x > 8'd186)) &&
                                      (($bullet_y < 8'd65) || ($bullet_y > 8'd191)) :
                                   (($bullet_y < 8'd70) || ($bullet_y > 8'd186)) &&
                                   (($bullet_x < 8'd65) || ($bullet_x > 8'd191)) :
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
                        (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/bullet_sprites/p2/bullet.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/bullet_sprites/p1/bullet.png"),
                        "",
                        { left: 0, top: 0,
                           width: 3, height: 16,
                           imageSmoothing: false }
                     );
                     ret.bullet_img.set({ originX: "center", originY: "center" });
               
               
                     // Create Bullet Rect:
                     ret.bullet_rect = new fabric.Rect({ width: 16, height: 2, strokeWidth: 0, fill: (player_id ? "#00ffb350" : "#ffff0050"), orginX: "center", originY: "center" });
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
               
               
                     // If moving forward cycles:
                     if (this.last_cycle < this.getCycle())
                     {
                        this.firing = '$successful_fire'.asBool();
               
                        // Set bullet image:
                        this.obj.bullet_img.set({
                           visible: this.firing || '$bullet_exists'.asBool(false) || ('>>1$bullet_exists'.asBool(false) && ! '$hit_an_enemy'.asBool()),
                           opacity: this.firing ? 0 : 1,
                           left: this.firing ? asSigned('/ship[ship_id]>>1$xx_p'.asInt(), 8) : asSigned('>>1$bullet_x'.asInt(), 8),
                           top: this.firing ? -asSigned('/ship[ship_id]>>1$yy_p'.asInt(), 8) : -asSigned('>>1$bullet_y'.asInt(), 8),
                           angle: ('$bullet_dir'.asInt() + 1) * 90,
                        });
                        // Set bullet rect:
                        this.obj.bullet_rect.set({
                           visible: this.obj.bullet_img.visible,
                           opacity: this.obj.bullet_img.opacity,
                           left: this.obj.bullet_img.left,
                           top: this.obj.bullet_img.top,
                           angle: this.obj.bullet_img.angle - 90
                        });
               
               
               
                        let anim_finish_visible = '$bullet_exists'.asBool();
               
                        // Animate bullet image:
                        this.obj.bullet_img.animate({
                           opacity: 1,
                           left: asSigned('$bullet_x'.asInt(), 8),
                           top: -asSigned('$bullet_y'.asInt(), 8),
                        }, {
                           duration: 180,
                           onComplete: () => {this.obj.bullet_img.set({ visible: anim_finish_visible})},
                           easing: fabric.util.ease.easeOutCubic
                        });
               
                        // Animate bullet rect:
                        this.obj.bullet_rect.animate({
                           opacity: 1,
                           left: asSigned('$bullet_x'.asInt(), 8),
                           top: -asSigned('$bullet_y'.asInt(), 8),
                        }, {
                           duration: 180,
                           onComplete: () => {this.obj.bullet_rect.set({ visible: anim_finish_visible})},
                           easing: fabric.util.ease.easeOutCubic
                        });
                     }
               
               
                     //If moving backwards cycles:
                     else
                     {
                        this.next_firing = '$successful_fire'.step().asBool();
               
                        // Set bullet image:
                        this.obj.bullet_img.set({
                           visible: ('$bullet_exists'.asBool() || '$bullet_exists'.step().asBool()) && ! '$hit_an_enemy'.step().asBool(),
                           opacity: 1,
                           left: asSigned('$bullet_x'.step().asInt(), 8),
                           top: -asSigned('$bullet_y'.step().asInt(), 8),
                           angle: this.next_firing ? ('$bullet_dir'.step().asInt() + 1) * 90 : ('$bullet_dir'.asInt() + 1) * 90
                        });
               
                        // Set bullet rect:
                        this.obj.bullet_rect.set({
                           visible: this.obj.bullet_img.visible,
                           opacity: this.obj.bullet_img.opacity,
                           left: this.obj.bullet_img.left,
                           top: this.obj.bullet_img.top,
                           angle: this.obj.bullet_img.angle - 90
                        });
               
               
               
                        let anim_finish_visible = '$bullet_exists'.asBool();
               
                        // Animate bullet image:
                        this.obj.bullet_img.animate({
                           opacity: this.next_firing ? 0 : 1,
                           left: this.next_firing ? asSigned('/ship[ship_id]$xx_p'.asInt(), 8) : asSigned('$bullet_x'.asInt(), 8),
                           top: this.next_firing ? -asSigned('/ship[ship_id]$yy_p'.asInt(), 8) : -asSigned('$bullet_y'.asInt(), 8),
                        }, {
                           duration: 180,
                           onComplete: () => {this.obj.bullet_img.set({ visible: anim_finish_visible})},
                           easing: fabric.util.ease.easeOutCubic
                        });
               
                        // Animate bullet rect:
                        this.obj.bullet_rect.animate({
                           opacity: this.next_firing ? 0 : 1,
                           left: this.next_firing ? asSigned('/ship[ship_id]$xx_p'.asInt(), 8) : asSigned('$bullet_x'.asInt(), 8),
                           top: this.next_firing ? -asSigned('/ship[ship_id]$yy_p'.asInt(), 8) : -asSigned('$bullet_y'.asInt(), 8),
                        }, {
                           duration: 180,
                           onComplete: () => {this.obj.bullet_rect.set({ visible: anim_finish_visible})},
                           easing: fabric.util.ease.easeOutCubic
                        });
                     }
               
                     //Save this cycle number for next render call
                     this.last_cycle = this.getCycle();
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
                     (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/ship0.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/ship0.png"),
                     "",
                     { left: 0, top: 0,
                        width: 15, height: 18,
                        imageSmoothing: false }
                  );
                  ret.ship_sprite0_img.set({ originX: "center", originY: "center" });
            
                  ret.ship_sprite1_img = this.newImageFromURL(
                     (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/ship1.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/ship1.png"),
                     "",
                     { left: 0, top: 0,
                        width: 15, height: 18,
                        imageSmoothing: false }
                  );
                  ret.ship_sprite1_img.set({ originX: "center", originY: "center" });
            
                  ret.ship_sprite2_img = this.newImageFromURL(
                     (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/ship2.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/ship2.png"),
                     "",
                     { left: 0, top: 0,
                        width: 15, height: 18,
                        imageSmoothing: false }
                  );
                  ret.ship_sprite2_img.set({ originX: "center", originY: "center" });
            
                  ret.ship_sprite3_img = this.newImageFromURL(
                     (player_id ? "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p2/ship3.png" : "https://raw.githubusercontent.com/PigNeck/space-scuffle/main/ship_sprites/p1/ship3.png"),
                     "",
                     { left: 0, top: 0,
                        width: 15, height: 18,
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
                  ret.shield_meter_back = new fabric.Rect({ width: 12, height: 2, strokeWidth: 0, fill: "#b0b0b0ff", originX: "left", originY: "center", angle: player_id ? 180.0 : 0.0 });
                  ret.shield_meter = new fabric.Rect({ width: 12, height: 2, strokeWidth: 0, fill: "#17f7ffff", originX: "left", originY: "center", angle: player_id ? 180.0 : 0.0 });
            
            
            
            
                  // Create Ship Rect:
                  ret.ship_rect = new fabric.Rect({ width: 10, height: 10, strokeWidth: 0, fill: (player_id ? "#00ffb350" : "#ffff0050"), originX: "center", originY: "center" });
            
            
            
            
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
                  let flip = 1;
            
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
            
            
                  const current_xx_p = asSigned('$xx_p'.asInt(), 8);
                  const current_yy_p = -asSigned('$yy_p'.asInt(), 8);
            
                  const shield_meter_x_offset = player_id ? 6 : -6;
                  const shield_meter_y_offset = player_id ? -10 : 10;
            
                  const temp_last_meter = '>>1$shield_counter'.asInt();
                  const temp_meter = '$shield_counter'.asInt();
                  const temp_next_meter = '$shield_counter'.step().asInt();
            
            
                  // If Moving Forward Cycles:
                  if (this.last_cycle <= this.getCycle())
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
                        left: current_ship_img.left + shield_meter_x_offset,
                        top: current_ship_img.top + shield_meter_y_offset,
                        visible: current_ship_img.visible
                     });
                     this.obj.shield_meter.set({
                        left: current_ship_img.left + shield_meter_x_offset,
                        top: current_ship_img.top + shield_meter_y_offset,
                        scaleX: //If in shield_up phase:
                                (temp_meter == 20) ? 1 :
                                (temp_meter > 14) ?
                                   (temp_last_meter <= 11) ? ((11 - temp_last_meter) / 11) :
                                   ((temp_meter - 14) / 5) :
            
                                //If in cool-down phase:
                                (temp_meter == 14) ? 1 :
                                (temp_meter > 10) ? ((temp_meter - 10) / 3) :
            
                                //If in charge-up phase:
                                ((10 - temp_meter) / 11),
                        fill: (temp_meter > 14) ? "#17f7ffff" :
                              (temp_meter > 10) ? "#de1010" :
                              "#12e32e",
                        visible: current_ship_img.visible
                     });
            
                     // Set shield:
                     this.obj.shield_img.set({
                        left: current_ship_img.left,
                        top: current_ship_img.top,
                        scaleX: '>>1$shield_up'.asBool() ? 1.0 : 0.0,
                        scaleY: '>>1$shield_up'.asBool() ? 1.0 : 0.0,
                        visible: ('$shield_up'.asBool() || '>>1$shield_up'.asBool()) && !'$destroyed'.asBool(),
                        opacity: 1.0
                     });
            
                     // Animate ship image:
                     let animateShip = current_ship_img.animate({
                        left: current_xx_p,
                        top: current_yy_p,
                        angle: animate_angle,
                     }, {
                        duration: 180,
                        easing: fabric.util.ease.easeOutCubic
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
                              .thenSet({left: current_xx_p, top: current_yy_p, visible: true})
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
                        left: current_xx_p,
                        top: current_yy_p,
                     }, {
                        duration: 180,
                        onComplete: () => {this.obj.ship_rect.set({ visible: !'$destroyed'.asBool()})},
                        easing: fabric.util.ease.easeOutCubic
                     });
            
                     // Animate shield meter:
                     this.obj.shield_meter_back.animate({
                        left: current_xx_p + shield_meter_x_offset,
                        top: current_yy_p + shield_meter_y_offset,
                     }, {
                        duration: 180,
                        onComplete: () => {this.obj.shield_meter_back.set({ visible: !'$destroyed'.asBool()})},
                        easing: fabric.util.ease.easeOutCubic
                     });
                     this.obj.shield_meter.animate({
                        left: current_xx_p + shield_meter_x_offset,
                        top: current_yy_p + shield_meter_y_offset,
                        scaleX: // If in shield_up phase:
                                (temp_meter > 14) ? ((temp_meter - 15) / 5) :
            
                                // If in cool-down phase:
                                (temp_meter > 10) ? ((temp_meter - 11) / 3) :
            
                                // If in charge-up phase:
                                ((11 - temp_meter) / 11)
                     }, {
                        duration: 180,
                        onComplete: () => {this.obj.shield_meter.set({ visible: !'$destroyed'.asBool() })},
                        easing: fabric.util.ease.easeOutCubic
                     });
            
            
                     // Animate shield:
                     this.obj.shield_img.animate({
                        left: current_xx_p,
                        top: current_yy_p,
                        scaleX: '$shield_up'.asBool() ? 1.0 :
                                '$shot'.asBool() ? 2.0 : 0.0,
                        scaleY: '$shield_up'.asBool() ? 1.0 :
                                '$shot'.asBool() ? 2.0 : 0.0,
                        opacity: '$shot'.asBool() ? 0.0 : 1.0
                     }, {
                        duration: 180,
                        onComplete: () => {this.obj.shield_img.set({ visible: !'$destroyed'.asBool() && this.obj.shield_img.visible })},
                        easing: fabric.util.ease.easeOutCubic
                     });
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
                              .thenSet({left: current_xx_p, top: current_yy_p, visible: true})
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
                        left: current_ship_img.left + shield_meter_x_offset,
                        top: current_ship_img.top + shield_meter_y_offset,
                        visible: current_ship_img.visible
                     });
                     this.obj.shield_meter.set({
                        left: current_ship_img.left + shield_meter_x_offset,
                        top: current_ship_img.top + shield_meter_y_offset,
                        scaleX: // If in shield_up phase:
                                (temp_meter > 15) ? ((temp_meter - 16) / 5) :
                                (temp_meter == 15) ? 0 :
            
                                // If in cool-down phase:
                                (temp_meter > 11) ? ((temp_meter - 12) / 3) :
            
                                // If in charge-up phase:
                                (temp_meter > 0) ?
                                   (temp_next_meter > 14) ? ((temp_next_meter - 15) / 5) :
                                   ((12 - temp_meter) / 11) :
                                1,
            
                        fill: (temp_meter > 15) ? "#17f7ffff" :
                              (temp_meter > 11) ? "#de1010" :
                              "#12e32e",
                        visible: current_ship_img.visible
                     });
            
                     // Set shield:
                     this.obj.shield_img.set({
                        left: current_ship_img.left,
                        top: current_ship_img.top,
                        scaleX: '$shield_up'.step().asBool() ? 1.0 :
                                '$hit'.step().asBool() ? 2.0 :
                                0.0,
                        scaleY: '$shield_up'.step().asBool() ? 1.0 :
                                '$hit'.step().asBool() ? 2.0 :
                                0.0,
                        visible: ('$shield_up'.asBool() || '$shield_up'.step().asBool()) && !'$destroyed'.step().asBool(),
                        opacity: '$hit'.step().asBool() ? 0.0 : 1.0
                     });
            
            
            
                     // Animate ship image:
                     current_ship_img.animate({
                        left: current_xx_p,
                        top: current_yy_p,
                        angle: animate_angle,
                     }, {
                        duration: 180,
                        easing: fabric.util.ease.easeOutCubic
                     });
            
                     // Animate ship rect:
                     this.obj.ship_rect.animate({
                        left: current_xx_p,
                        top: current_yy_p,
                     }, {
                        duration: 180,
                        easing: fabric.util.ease.easeOutCubic
                     });
            
                     // Animate shield meter:
                     this.obj.shield_meter_back.animate({
                        left: current_xx_p + shield_meter_x_offset,
                        top: current_yy_p + shield_meter_y_offset,
                     }, {
                        duration: 180,
                        onComplete: () => {this.obj.shield_meter_back.set({ visible: !'$destroyed'.asBool()})},
                        easing: fabric.util.ease.easeOutCubic
                     });
                     this.obj.shield_meter.animate({
                        left: current_xx_p + shield_meter_x_offset,
                        top: current_yy_p + shield_meter_y_offset,
                        scaleX: //If in shield_up phase:
                                (temp_meter > 14) ? ((temp_meter - 15) / 5) :
            
                                //If in cool-down phase:
                                (temp_meter > 10) ? ((temp_meter - 11) / 3) :
            
                                //If in charge-up phase:
                                ((11 - temp_meter) / 11)
                     }, {
                        duration: 180,
                        onComplete: () => {this.obj.shield_meter.set({ visible: !'$destroyed'.asBool() })},
                        easing: fabric.util.ease.easeOutCubic
                     });
            
                     // Animate shield:
                     this.obj.shield_img.animate({
                        left: current_xx_p,
                        top: current_yy_p,
                        scaleX: '$shield_up'.asBool() ? 1.0 : 0.0,
                        scaleY: '$shield_up'.asBool() ? 1.0 : 0.0,
                        opacity: 1.0,
                     }, {
                        duration: 180,
                        onComplete: () => {this.obj.shield_img.set({ visible: '$shield_up'.asBool() && !'$destroyed'.asBool()})},
                        easing: fabric.util.ease.easeOutCubic
                     });
                  }
            
            
              // Save this cycle number for next render call
               this.last_cycle = this.getCycle();
               }
      
      
      
      
      /background
         // ================  FOREGROUND VIZ  ================
         \viz_js
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
               let animateEndScreen = (end_screen, last_win_id) => {
                  if (last_win_id == 0)
                  {
                     end_screen.set({visible: true, top: -164});
                     end_screen.animate({
                        top: -64,
                     }, {
                        duration: 1000,
                        easing: fabric.util.ease.easeOutCubic
                     });
                  }
                  else
                  {
                     end_screen.set({visible: true, top: -64});
                  }
               }
         
               let animateEndScreenReverse = (end_screen, last_win_id) => {
                  if (last_win_id == 0)
                  {
                     end_screen.set({visible: true, top: -64});
                     end_screen.animate({
                        top: -164,
                     }, {
                        duration: 1000,
                        easing: fabric.util.ease.easeOutCubic
                     });
                  }
                  else
                  {
                     end_screen.set({visible: true, top: -64});
                  }
               }
         
         
               let $win_id = '/_showdown['']_['']_hidden$win_id';
               let win_id_0 = $win_id.asInt();
               let win_id_1 = $win_id.step(-1).asInt();
               let win_id_2 = $win_id.step(-1).asInt();
         
               // If Moving Forward Cycles:
               if (this.last_cycle < this.getCycle())
               {
                  // Animate endscreen if applicable:
                  if (win_id_1 != 0)
                  {
                     debugger
                     animateEndScreen(
                        (win_id_1 == 1) ? this.obj.p1win_img :
                        (win_id_1 == 2) ? this.obj.p2win_img :
                        this.obj.tie_img,
                        win_id_2
                     );
                  }
                  else
                  {
                     this.obj.p1win_img.set({visible: false});
                     this.obj.p2win_img.set({visible: false});
                     this.obj.tie_img.set({visible: false});
                  }
               }
         
         
               // If Moving Backward Cycles:
               else
               {
                  // Animate endscreen if applicable:
                  if (win_id_0 != 0)
                  {
                     animateEndScreenReverse(
                        (win_id_0 == 1) ? this.obj.p1win_img :
                        (win_id_0 == 2) ? this.obj.p2win_img :
                        this.obj.tie_img,
                        win_id_1
                     );
                  }
                  else
                  {
                     this.obj.p1win_img.set({visible: false});
                     this.obj.p2win_img.set({visible: false});
                     this.obj.tie_img.set({visible: false});
                  }
               }
         
               // Save last cycle number for next render call
               this.last_cycle = this.getCycle();
            }
      
      
      
      
      // Assert these to end simulation (before Makerchip cycle limit).
      *passed = | /player[*]>>30$lost;
      *failed = *cyc_cnt > 600;










\SV
   m5_team_tlv_url()
   m5_team_tlv_url()
   m5_makerchip_module
\TLV
   $reset = *reset;
   
   // Instantiate the Showdown environment.
   m5+showdown(/top, /showdown, hidden, , )
   /**
   m5+showdown(
      /top, /showdown,
      hidden, /// A tag used to hide opponent logic that will be given an unknown value in competition. Contestants, be sure your code works for a value of "something_else" as well.
      ['https://raw.githubusercontent.com/stevehoover/drop4game/6baddeb046a3e261bb45bbc2cb879cd8c9931778/player_template.tlv'],   /// Team 1's logic (or empty for random opponent)
      ['https://raw.githubusercontent.com/stevehoover/drop4game/6baddeb046a3e261bb45bbc2cb879cd8c9931778/player_template.tlv'])   /// Team 2's logic (or empty for random opponent)
   **/
\SV
   endmodule
