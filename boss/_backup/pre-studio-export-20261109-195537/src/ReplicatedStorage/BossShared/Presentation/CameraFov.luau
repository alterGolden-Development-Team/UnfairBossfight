local F={}
local offsets=setmetatable({},{__mode="k"})
local camera
local baseline
local function current()
 local cam=workspace.CurrentCamera
 if cam~=camera then
  if camera and baseline then camera.FieldOfView=baseline end
  camera=cam baseline=cam and cam.FieldOfView or 70
 end
 return cam
end
local function apply()
 local cam=current()
 if not cam or cam.CameraType==Enum.CameraType.Scriptable then return end
 local total=0
 for _,value in pairs(offsets)do total+=value end
 cam.FieldOfView=math.clamp(baseline+total,20,110)
end
function F.Base(cam)
 current()
 return cam==camera and baseline or cam and cam.FieldOfView or baseline or 70
end
function F.Set(owner,value)
 local nextValue=math.abs(value or 0)>.001 and value or nil
 if offsets[owner]==nil and nextValue==nil then return end
 offsets[owner]=nextValue
 apply()
end
function F.Clear(owner)if offsets[owner]==nil then return end offsets[owner]=nil apply()end
function F.Reset()
 table.clear(offsets)
 local cam=current()
 if cam then cam.FieldOfView=baseline end
end
current()
return F
