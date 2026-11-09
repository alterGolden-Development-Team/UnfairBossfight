local S={}
function S.New(amounts,interval,now,immediate)
 assert(type(amounts)=="table"and #amounts>0 and #amounts<=32,"Invalid burn sequence")
 assert(type(interval)=="number"and interval>=.1 and interval<=10,"Invalid burn interval")
 for _,amount in ipairs(amounts)do assert(type(amount)=="number"and amount>0 and amount<10000,"Invalid burn damage")end
 return {Amounts=table.clone(amounts),Interval=interval,Index=1,NextTick=now+(immediate and 0 or interval)}
end
function S.Deadline(stream)
 return stream.NextTick+math.max(0,#stream.Amounts-stream.Index)*stream.Interval+.25
end
function S.Take(stream,now)
 if stream.Index>#stream.Amounts or now+.001<stream.NextTick then return nil end
 local amount=stream.Amounts[stream.Index]stream.Index+=1
 stream.NextTick=math.max(stream.NextTick+stream.Interval,now+stream.Interval)
 return amount
end
function S.Done(stream)return stream.Index>#stream.Amounts end
return table.freeze(S)
