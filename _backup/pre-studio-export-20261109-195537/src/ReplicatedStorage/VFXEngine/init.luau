--[[
 VFXEngine (client core)

 A small layer-based effect engine. Effects are composed from a few primitives:
   Sprite  one long-lived particle used as an animated billboard or flat ground decal.
           Size/alpha/colour curves run on the GPU over the particle's life, so a
           sprite costs no Lua per frame and blends additively.
   Emit    a burst of particles from a spec table (sparks, smoke, twinkles).
   Beam    a textured, scrolling ribbon between two attachments (aurora, pillars, threads).
   Light   a PointLight flash that decays.
 Everything an effect creates goes into a Group, so cancelling or finishing an effect
 is one call. Textures come from VFXEngine.Library by key.

 Spec fields (Sprite / Emit):
   tex     library key            size   number | {{t,v},...} | NumberSequence
   alpha   same as size           color  Color3 | {{t,c},...} | ColorSequence
   life    number | {min,max}     speed  number | {min,max}
   spread  number (degrees)       rot    {min,max}   spin {min,max}
   drag, accel(Vector3), squash, z (ZOffset), light (LightEmission, default from lib blend)
   orient  "camera" | "flat" | "velocity"
   shape   Enum.ParticleEmitterShape, inout, style   fps (flipbook framerate)
]]
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")

local E={}
E.Lib=require(script.Library)
E.Net=require(script.Net)
E.Sky=Run:IsClient()and require(script.Sky)or nil
E.Quality=1

local NK,CK=NumberSequenceKeypoint.new,ColorSequenceKeypoint.new
local WHITE=Color3.new(1,1,1)

local root
local function folder()
 if root and root.Parent then return root end
 root=Instance.new("Folder")root.Name="VFXEngineLocal"root.Parent=workspace
 return root
end

 -- sequences -----------------------------------------------------------------
local function nseq(v,scale)
 scale=scale or 1
 if typeof(v)=="NumberSequence"then
  if scale==1 then return v end
  local k={}
  for _,p in ipairs(v.Keypoints)do k[#k+1]=NK(p.Time,p.Value*scale,p.Envelope*scale)end
  return NumberSequence.new(k)
 elseif type(v)=="table"then
  local k={}
  for _,p in ipairs(v)do k[#k+1]=NK(p[1],p[2]*scale)end
  return NumberSequence.new(k)
 end
 return NumberSequence.new((v or 1)*scale)
end
local function cseq(v)
 if typeof(v)=="ColorSequence"then return v end
 if typeof(v)=="Color3"then return ColorSequence.new(v)end
 if type(v)=="table"then
  local k={}
  for _,p in ipairs(v)do k[#k+1]=CK(p[1],p[2])end
  return ColorSequence.new(k)
 end
 return ColorSequence.new(WHITE)
end
local function range(v,d)
 if typeof(v)=="NumberRange"then return v end
 if type(v)=="table"then return NumberRange.new(v[1],v[2])end
 if type(v)=="number"then return NumberRange.new(v)end
 return d
end
E.NSeq,E.CSeq,E.Range=nseq,cseq,range

 -- colour helpers
function E.Tint(c,a)return c:Lerp(WHITE,a)end
function E.Shade(c,a)return c:Lerp(Color3.fromRGB(10,14,40),a)end

 -- groups ---------------------------------------------------------------------
local Group={}
Group.__index=Group
function E.Group(name)
 local f=Instance.new("Folder")f.Name=name or"Effect"f.Parent=folder()
 return setmetatable({Folder=f,Alive=true,Conns={},Beams={},Lights={}},Group)
end
function Group:Add(inst)inst.Parent=inst.Parent or self.Folder return inst end
function Group:Destroy()
 if not self.Alive then return end
 self.Alive=false
 for _,c in ipairs(self.Conns)do c:Disconnect()end
 self.Folder:Destroy()
end
 -- shrink beams and lights, stop emitters, then destroy
function Group:Fade(t)
 if not self.Alive then return end
 t=t or 1
 for _,b in ipairs(self.Beams)do
  if b.Parent then E.Tween(b,t,{Width0=0,Width1=0,Brightness=0},Enum.EasingStyle.Quad,Enum.EasingDirection.In)end
 end
 for _,l in ipairs(self.Lights)do if l.Parent then E.Tween(l,t,{Brightness=0})end end
 for _,d in ipairs(self.Folder:GetDescendants())do
  if d:IsA("ParticleEmitter")then d.Enabled=false end
 end
 task.delay(t+.1,function()self:Destroy()end)
end

function E.After(g,t,fn)
 task.delay(t,function()if g.Alive then fn()end end)
end

 -- per-frame update bound to the group; return false from fn to stop
function E.Step(g,fn)
 local start=os.clock()
 local c
  -- RenderStepped doesn't fire in Studio edit mode; Heartbeat lets effects preview there
 local signal=Run:IsRunning()and Run.RenderStepped or Run.Heartbeat
 c=signal:Connect(function(dt)
  if not g.Alive then c:Disconnect()return end
  local ok,keep=pcall(fn,dt,os.clock()-start)
  if not ok then warn("[VFXEngine] step error: "..tostring(keep))c:Disconnect()return end
  if keep==false then c:Disconnect()end
 end)
 g.Conns[#g.Conns+1]=c
 return c
end

function E.Tween(inst,t,props,style,dir,delay)
 local tw=Tween:Create(inst,TweenInfo.new(t,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out,0,false,delay or 0),props)
 tw:Play()
 return tw
end

 -- anchors --------------------------------------------------------------------
function E.Anchor(g,cf)
 local p=Instance.new("Part")
 p.Name="Anchor"p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false
 p.CastShadow=false p.Transparency=1 p.Size=Vector3.one*.2
 p.CFrame=typeof(cf)=="Vector3"and CFrame.new(cf)or cf or CFrame.new()
 p.Parent=g and g.Folder or folder()
 return p
end

function E.Ground(pos,ignore)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local list={folder()}
 for _,i in ipairs(ignore or{})do list[#list+1]=i end
 params.FilterDescendantsInstances=list
 local hit=workspace:Raycast(pos,Vector3.new(0,-500,0),params)
 return hit and hit.Position or nil
end

 -- particles ------------------------------------------------------------------
local ORIENT={
 camera=Enum.ParticleOrientation.FacingCamera,
 flat=Enum.ParticleOrientation.VelocityPerpendicular,
 velocity=Enum.ParticleOrientation.VelocityParallel,
 upright=Enum.ParticleOrientation.FacingCameraWorldUp,
}

function E.Emitter(parent,s,scale)
 scale=scale or 1
 local lib=E.Lib.Get(s.tex or"sparkle")or{}
 local e=Instance.new("ParticleEmitter")
 e.Enabled=false
 e.Rate=s.rate or 0
 e.Texture=E.Lib.Id(s.tex or"sparkle")
 e.Size=nseq(s.size or 1,scale)
 e.Transparency=nseq(s.alpha or{{0,0},{.8,0},{1,1}})
 e.Color=cseq(s.color)
 e.Lifetime=range(s.life,NumberRange.new(1))
 e.Speed=range(s.speed,NumberRange.new(0))
 e.SpreadAngle=Vector2.new(s.spread or 0,s.spread or 0)
 e.Rotation=range(s.rot,NumberRange.new(0,360))
 e.RotSpeed=range(s.spin,NumberRange.new(0))
 e.Drag=s.drag or 0
 e.Acceleration=s.accel or Vector3.zero
 e.LightEmission=s.light or(lib.blend=="alpha"and 0 or 1)
 e.LightInfluence=0
 e.Brightness=s.brightness or 1
 e.ZOffset=s.z or 0
 e.LockedToPart=s.locked or false
 e.Orientation=ORIENT[s.orient or"camera"]
 if s.orient=="flat"then
   -- flat particles lie perpendicular to their velocity, so they need a tiny upward
   -- speed to orient; a given speed makes them rise (e.g. rings climbing a column)
  e.EmissionDirection=Enum.NormalId.Top
  e.Speed=s.speed and range(s.speed)or NumberRange.new(.001)
  e.SpreadAngle=Vector2.zero
 end
 if s.orient=="velocity"then e.Rotation=NumberRange.new(0)e.RotSpeed=NumberRange.new(0)end
 if s.squash then e.Squash=nseq(s.squash)end
 if s.shape then e.Shape=s.shape end
 if s.inout then e.ShapeInOut=s.inout end
 if s.style then e.ShapeStyle=s.style end
 if s.dir then e.EmissionDirection=s.dir end
 local flip=s.flip or lib.flip
 if flip then
  e.FlipbookLayout=Enum.ParticleFlipbookLayout[flip]
  e.FlipbookMode=s.fps and Enum.ParticleFlipbookMode.Loop or Enum.ParticleFlipbookMode.OneShot
  if s.fps then e.FlipbookFramerate=range(s.fps)end
 end
 e.Parent=parent
 return e
end

 -- burst `count` particles, emitter removes itself after the longest lifetime
function E.Emit(parent,s,count,scale)
 local e=E.Emitter(parent,s,scale)
 e:Emit(math.max(1,math.floor((count or 1)*(s.lod==false and 1 or E.Quality)+.5)))
 Debris:AddItem(e,e.Lifetime.Max+.2)
 return e
end

 -- one particle that lives `life` seconds: an animated billboard or ground decal
function E.Sprite(parent,s,life,scale)
 local spec=table.clone(s)
 spec.life=life
 spec.locked=spec.locked~=false
 spec.lod=false
 if spec.orient~="flat"then spec.speed=0 end
 return E.Emit(parent,spec,1,scale)
end

 -- continuous emitter (rate per second) the caller toggles
function E.Stream(parent,s,rate,scale)
 local e=E.Emitter(parent,s,scale)
 e.Rate=rate*E.Quality
 e.Enabled=true
 return e
end

 -- beams ----------------------------------------------------------------------
function E.Beam(g,a0,a1,s)
 local b=Instance.new("Beam")
 b.Attachment0=a0 b.Attachment1=a1
 b.Texture=s.tex and E.Lib.Id(s.tex)or""
 b.TextureMode=s.mode or Enum.TextureMode.Wrap
 b.TextureLength=s.length or 10
 b.TextureSpeed=s.scroll or 0
 b.Color=cseq(s.color)
 b.Transparency=nseq(s.alpha or 0)
 b.Width0=s.width0 or s.width or 1
 b.Width1=s.width1 or s.width or 1
 b.CurveSize0=s.curve0 or 0
 b.CurveSize1=s.curve1 or 0
 b.Segments=s.segments or 16
 b.FaceCamera=s.face~=false
 b.LightEmission=s.light or 1
 b.LightInfluence=0
 b.Brightness=s.brightness or 1
 b.ZOffset=s.z or 0
 b.Parent=a0.Parent
 g.Beams[#g.Beams+1]=b
 return b
end

function E.Attach(part,cf)
 local a=Instance.new("Attachment")
 if cf then a.CFrame=cf end
 a.Parent=part
 return a
end

 -- lights ---------------------------------------------------------------------
function E.Light(g,parent,color,range,brightness,life)
 local l=Instance.new("PointLight")
 l.Color=color l.Range=range l.Brightness=brightness l.Shadows=false
 l.Enabled=E.Lights~=false  -- off on the Low effects setting
 l.Parent=parent
 g.Lights[#g.Lights+1]=l
 if life then
  E.Tween(l,life,{Brightness=0},Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
  Debris:AddItem(l,life+.1)
 end
 return l
end

 -- preload every library texture once so first casts don't pop in
local preloaded=false
function E.Preload()
 if preloaded or not Run:IsClient()then return end
 preloaded=true
 task.spawn(function()
  local list={}
  for _,id in ipairs(E.Lib.All())do
   local d=Instance.new("Decal")d.Texture=id list[#list+1]=d
  end
  pcall(function()game:GetService("ContentProvider"):PreloadAsync(list)end)
 end)
end

return E
