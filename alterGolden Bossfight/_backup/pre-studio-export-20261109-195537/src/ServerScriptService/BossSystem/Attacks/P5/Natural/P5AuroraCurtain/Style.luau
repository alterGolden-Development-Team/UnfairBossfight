 -- Aurora Curtain (Natural mode): he lifts his arms and the northern lights come down - golden ones. Sweeps walls of
 -- aurora sweep across the arena one after another, each from a different direction, Span long and Height tall, with no
 -- gap in them: dash through, or HOLD E as one reaches you (the shield cue comes up), or take Damage. Each curtain's
 -- starting line glows for Warn seconds first. Once he has called them down they sweep on their own (a background cast),
 -- so he goes on attacking while they do; he won't call another set while one is still sweeping.
return table.freeze({
	Name = "P5AuroraCurtain", Cooldown = 16,
	Tell = 0.6, Sweeps = 3, Warn = 0.9, SweepTime = 2.1, SweepGap = 0.5, Span = 300, Distance = 140, Height = 40, Thickness = 5,
	Damage = 55,
})
