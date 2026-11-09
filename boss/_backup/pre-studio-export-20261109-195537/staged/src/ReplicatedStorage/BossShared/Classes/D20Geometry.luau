local G={}
local phi=(1+math.sqrt(5))/2
local vertices={
 Vector3.new(-1,phi,0),Vector3.new(1,phi,0),Vector3.new(-1,-phi,0),Vector3.new(1,-phi,0),
 Vector3.new(0,-1,phi),Vector3.new(0,1,phi),Vector3.new(0,-1,-phi),Vector3.new(0,1,-phi),
 Vector3.new(phi,0,-1),Vector3.new(phi,0,1),Vector3.new(-phi,0,-1),Vector3.new(-phi,0,1),
}
for i,v in vertices do vertices[i]=v.Unit end
local faces={{1,12,6},{1,6,2},{1,2,8},{1,8,11},{1,11,12},{2,6,10},{6,12,5},{12,11,3},{11,8,7},{8,2,9},
 {4,10,5},{4,5,3},{4,3,7},{4,7,9},{4,9,10},{5,10,6},{3,5,12},{7,3,11},{9,7,8},{10,9,2}}
local normals,numbers={},{}
for i,f in faces do
 local n=(vertices[f[2]]-vertices[f[1]]):Cross(vertices[f[3]]-vertices[f[1]]).Unit
 if n:Dot(vertices[f[1]])<0 then f[2],f[3]=f[3],f[2]n=-n end
 normals[i]=n
end
local nextNumber=1
for i in faces do if not numbers[i]then
 local opposite
 for j,n in normals do if normals[i]:Dot(n)<-.999 then opposite=j break end end
 numbers[i]=nextNumber numbers[assert(opposite)]=21-nextNumber nextNumber+=1
end end
local function part(class,name,size,frame,color,parent,root)
 local p=Instance.new(class)p.Name=name p.Size=size p.CFrame=frame p.Color=color
 p.Material=Enum.Material.SmoothPlastic p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true
 p:SetAttribute("ClassWeapon",true)p.Parent=parent
 if root then local w=Instance.new("WeldConstraint")w.Part0=root w.Part1=p w.Parent=p end
 return p
end
local function triangle(parent,root,a,b,c,color,name)
 if (b-a).Magnitude<(c-a).Magnitude then b,c=c,b end
 if (b-a).Magnitude<(c-b).Magnitude then a,c=c,a end
 local along=(b-a).Unit local normal=(b-a):Cross(c-a).Unit
 local up=normal:Cross(along).Unit local distance=(c-a):Dot(along)
 local foot=a+along*distance local height=(c-foot).Magnitude
 local thickness=.015
 part("WedgePart",name.."A",Vector3.new(thickness,height,distance),CFrame.fromMatrix((a+c)/2,-normal,up,along),color,parent,root)
 part("WedgePart",name.."B",Vector3.new(thickness,height,(b-foot).Magnitude),CFrame.fromMatrix((b+c)/2,normal,up,-along),color,parent,root)
end
function G.FaceUp(value)
 local normal
 for i,n in numbers do if n==value then normal=normals[i]break end end
 normal=assert(normal)
 local axis=normal:Cross(Vector3.yAxis)
 if axis.Magnitude<.001 then return normal.Y>0 and CFrame.identity or CFrame.Angles(math.pi,0,0)end
 return CFrame.fromAxisAngle(axis.Unit,math.acos(math.clamp(normal.Y,-1,1)))
end
function G.Build(parent,frame,diameter,anchored)
 local model=Instance.new("Model")model.Name="GamblerD20"model:SetAttribute("Faces",20)
 local root=part("Part","Die",Vector3.one*.05,frame,Color3.new(1,1,1),model)
 root.Transparency=1 root.Anchored=anchored==true model.PrimaryPart=root
 local radius=diameter*.5
 for i,f in faces do
  local a,b,c=vertices[f[1]]*radius,vertices[f[2]]*radius,vertices[f[3]]*radius
  local color=i%2==0 and Color3.fromRGB(245,203,94) or Color3.fromRGB(212,159,58)
  triangle(model,root,frame:PointToWorldSpace(a),frame:PointToWorldSpace(b),frame:PointToWorldSpace(c),color,"Face"..i)
  local center=frame:PointToWorldSpace((a+b+c)/3+normals[i]*.012)
  local normal=frame:VectorToWorldSpace(normals[i])
  local plate=part("Part","Number"..numbers[i],Vector3.new(diameter*.24,diameter*.24,.005),CFrame.lookAt(center,center+normal),color,model,root)
  plate.Transparency=1
  local gui=Instance.new("SurfaceGui")gui.Name="FaceNumber"gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(96,96)
  gui.LightInfluence=0 gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize gui.Parent=plate
  local label=Instance.new("TextLabel")label.Size=UDim2.fromScale(1,1)label.BackgroundTransparency=1
  label.Text=tostring(numbers[i])label.TextScaled=true label.Font=Enum.Font.GothamBold
  label.TextColor3=numbers[i]==1 and Color3.fromRGB(160,30,30) or numbers[i]==20 and Color3.fromRGB(24,100,55) or Color3.fromRGB(35,26,14)
  label.Parent=gui
 end
 model.Parent=parent
 return model
end
G.Numbers=table.freeze(numbers)
return table.freeze(G)
