--[[
 VFXEngine.Library
 Role-tagged texture library. Effects ask for a texture by key (Lib.Id "star.lens")
 or query by tags (Lib.Find{role="ring",edge="soft"}) so the same effect code can be
 re-skinned by swapping entries here.

 Fields:
  id       asset id
  role     what the texture is for: star, glow, ring, sigil, burst, swirl, streak, beam, smoke, spark, reticle
  edge     hard | soft
  blend    add (LightEmission 1) | alpha (LightEmission 0)
  flip     flipbook layout enum name (Grid2x2 / Grid4x4 / Grid8x8)
  tags     free-form descriptors
 Source: Alex's VFX Texture Pack (Creator Store 15527901599), Roblox built-ins.
]]
local Lib={}

local E={
 -- stars and flares
 ["star.lens"]      ={id=14032952906,role="star",edge="soft",blend="add",tags={"4point","chromatic","polaris"}},
 ["star.glare"]     ={id=14198353638,role="star",edge="soft",blend="add",tags={"4point","long","glare"}},
 ["star.glare2"]    ={id=14197583306,role="star",edge="soft",blend="add",tags={"4point","chromatic"}},
 ["star.crisp"]     ={id=7216848960 ,role="star",edge="hard",blend="add",tags={"4point","node"}},
 ["star.anime"]     ={id=9563725822 ,role="star",edge="hard",blend="add",tags={"4point","solid"}},
 ["star.thin"]      ={id=14221498728,role="star",edge="hard",blend="add",tags={"4point","thin"}},
 ["star.twinkle"]   ={id=15268036910,role="spark",edge="soft",blend="add",tags={"small","twinkle"}},
 ["star.twinkle2"]  ={id=15268042395,role="spark",edge="soft",blend="add",tags={"small","twinkle"}},
 ["star.tiny"]      ={id=669133414  ,role="spark",edge="hard",blend="add",tags={"small"}},
 ["flare.burst"]    ={id=15267976180,role="burst",edge="soft",blend="add",tags={"flash","rays"}},
 ["flare.burst2"]   ={id=15267990211,role="burst",edge="soft",blend="add",tags={"flash","rays"}},
 ["flare.big"]      ={id=11815755770,role="burst",edge="soft",blend="add",tags={"flash","finale"}},
 ["flare.streak"]   ={id=15267955654,role="streak",edge="soft",blend="add",tags={"anamorphic","lens"}},
 ["glow.soft"]      ={id=15267968986,role="glow",edge="soft",blend="add",tags={"orb"}},
 ["glow.rays"]      ={id=507021722  ,role="glow",edge="soft",blend="add",tags={"radial"}},
 -- rings and circles
 ["ring.compass"]   ={id=15268108437,role="ring",edge="soft",blend="add",tags={"spikes","north","polaris"}},
 ["ring.soft"]      ={id=15268062056,role="ring",edge="soft",blend="add",tags={"shockwave"}},
 ["ring.thick"]     ={id=15268066299,role="ring",edge="soft",blend="add",tags={"shockwave"}},
 ["ring.inverse"]   ={id=15268080306,role="ring",edge="soft",blend="add",tags={"shockwave","filled"}},
 ["ring.crisp"]     ={id=1084952073 ,role="ring",edge="hard",blend="add",tags={"line"}},
 ["ring.thin"]      ={id=12201347372,role="ring",edge="hard",blend="add",tags={"line","thin"}},
 ["ring.hair"]      ={id=5466155927 ,role="ring",edge="hard",blend="add",tags={"line","hairline"}},
 ["ring.multi"]     ={id=12074939493,role="ring",edge="soft",blend="add",tags={"layered"}},
 ["ring.ticked"]    ={id=15268104281,role="ring",edge="soft",blend="add",tags={"ticks"}},
 ["ring.dots"]      ={id=15268071837,role="ring",edge="hard",blend="add",tags={"constellation","dots"}},
 ["orb.shaded"]     ={id=15268126916,role="glow",edge="hard",blend="add",tags={"sphere"}},
 ["disc.soft"]      ={id=8788474862 ,role="glow",edge="soft",blend="add",tags={"disc"}},
 ["vortex.soft"]    ={id=15268068246,role="swirl",edge="soft",blend="add",tags={"vortex"}},
 -- magic circles
 ["sigil.mandala"]  ={id=12403097047,role="sigil",edge="hard",blend="add",tags={"ornate","circle"}},
 ["sigil.mandala2"] ={id=12403075151,role="sigil",edge="hard",blend="add",tags={"ornate","lace"}},
 ["sigil.ring"]     ={id=12389948201,role="sigil",edge="hard",blend="add",tags={"ornate","thin"}},
 ["sigil.ring2"]    ={id=12389945119,role="sigil",edge="hard",blend="add",tags={"ornate"}},
 ["reticle"]        ={id=9563595028 ,role="reticle",edge="hard",blend="add",tags={"crosshair","telegraph"}},
 ["frost.flake"]    ={id=12389944487,role="sigil",edge="hard",blend="add",tags={"snowflake","frost","borealis"}},
 ["frost.flake2"]   ={id=14197923174,role="sigil",edge="soft",blend="add",tags={"snowflake","frost"}},
 ["sigil.lace"]     ={id=12403078255,role="sigil",edge="hard",blend="add",tags={"ornate","lace","frost"}},
 -- bursts and swirls
 ["burst.spiky"]    ={id=15268140795,role="burst",edge="hard",blend="add",tags={"impact","ring"}},
 ["burst.spiky2"]   ={id=15268142082,role="burst",edge="hard",blend="add",tags={"impact","ring"}},
 ["burst.ice"]      ={id=15268162583,role="burst",edge="hard",blend="add",tags={"impact","cyan","colored"}},
 ["burst.fringe"]   ={id=15268154903,role="burst",edge="hard",blend="add",tags={"impact","chromatic","colored"}},
 ["burst.white"]    ={id=15268144255,role="burst",edge="hard",blend="add",tags={"impact"}},
 ["swirl.blue"]     ={id=15268172222,role="swirl",edge="soft",blend="add",tags={"gather","colored"}},
 ["swirl.white"]    ={id=14050423054,role="swirl",edge="soft",blend="add",tags={"gather"}},
 ["swirl.lines"]    ={id=1244829143 ,role="swirl",edge="hard",blend="add",tags={"whirl"}},
 -- beams and ribbons (streaks run vertically in the image = across the beam width)
 ["beam.curtain"]   ={id=9035801067 ,role="beam",edge="soft",blend="add",tags={"aurora","drips"}},
 ["beam.wisp"]      ={id=14191603094,role="beam",edge="soft",blend="add",tags={"aurora","wisp"}},
 ["beam.streaks"]   ={id=14050983225,role="beam",edge="soft",blend="add",tags={"aurora","soft"}},
 ["beam.core"]      ={id=15270335786,role="beam",edge="soft",blend="add",tags={"pillar","core"}},
 ["beam.stars"]     ={id=2316283203 ,role="beam",edge="soft",blend="add",tags={"pillar","stars"}},
 ["beam.dots"]      ={id=1851669703 ,role="beam",edge="hard",blend="add",tags={"starfield","thread"}},
 ["beam.ribbon"]    ={id=12788868051,role="beam",edge="soft",blend="add",tags={"ribbon","wave"}},
 -- flipbooks: Roblox only animates 1024x1024 sheets; these reported FlipbookIncompatible,
 -- so effects use static textures until 1024px versions are uploaded
 ["fb.ringburst"]   ={id=15011478368,role="ring",edge="soft",blend="add",flip="Grid4x4",tags={"shockwave","animated"}},
 ["fb.ringexpand"]  ={id=12239789629,role="ring",edge="hard",blend="add",flip="Grid4x4",tags={"shockwave","animated"}},
 ["fb.smoke"]       ={id=12799115725,role="smoke",edge="soft",blend="alpha",flip="Grid4x4",tags={"puff","animated"}},
 ["fb.smoke2"]      ={id=14197126377,role="smoke",edge="soft",blend="alpha",flip="Grid4x4",tags={"puff","animated"}},
 ["fb.arc"]         ={id=11341694984,role="spark",edge="hard",blend="add",flip="Grid2x2",tags={"electric","animated"}},
 -- combat slashes and butterflies (Creator Store, free; P5 normal attacks). These are the image ids
 -- behind the store decals: a decal id fails at runtime ("Asset type does not match")
 ["claw.lines"]     ={id=72992688549400,role="streak",edge="hard",blend="add",tags={"claw","3lines"}},
 ["claw.marks"]     ={id=8175147837,role="streak",edge="soft",blend="add",tags={"claw","scratch"}},
 ["slash.streak"]   ={id=8273465648,role="streak",edge="soft",blend="add",tags={"slash","wind"}},
 ["wind.dash"]      ={id=134686613460761,role="streak",edge="soft",blend="add",tags={"dash","wind","cone"}},
 ["butterfly"]      ={id=11183559491,role="spark",edge="hard",blend="add",tags={"butterfly","white"}},
 ["butterfly.monarch"]={id=5832471245,role="spark",edge="hard",blend="alpha",tags={"butterfly","monarch"}},
 -- built-ins
 ["dot"]            ={id="rbxasset://textures/whiteCircle.png",role="spark",edge="hard",blend="add",tags={"dot"}},
 ["sparkle"]        ={id="rbxasset://textures/particles/sparkles_main.dds",role="spark",edge="soft",blend="add",tags={}},
 ["smoke"]          ={id="rbxasset://textures/particles/smoke_main.dds",role="smoke",edge="soft",blend="alpha",tags={}},
 ["fire"]           ={id="rbxasset://textures/particles/fire_main.dds",role="fire",edge="soft",blend="add",tags={"fireball"}},
 ["fire.sparks"]    ={id="rbxasset://textures/particles/fire_sparks_main.dds",role="spark",edge="soft",blend="add",tags={"embers"}},
}
Lib.Entries=E

function Lib.Id(key)
 local e=E[key]
 if not e then warn("[VFXEngine] unknown texture "..tostring(key))return "" end
 return type(e.id)=="number"and"rbxassetid://"..e.id or e.id
end

function Lib.Get(key)return E[key]end

 -- every entry whose fields match the query; a `tag` field matches against tags
function Lib.Find(q)
 local out={}
 for key,e in pairs(E)do
  local ok=true
  for k,v in pairs(q)do
   if k=="tag"then ok=ok and table.find(e.tags,v)~=nil
   elseif e[k]~=v then ok=false end
  end
  if ok then out[#out+1]=key end
 end
 table.sort(out)
 return out
end

function Lib.All()
 local out={}
 for key,e in pairs(E)do out[#out+1]=Lib.Id(key)end
 return out
end

return table.freeze(Lib)
