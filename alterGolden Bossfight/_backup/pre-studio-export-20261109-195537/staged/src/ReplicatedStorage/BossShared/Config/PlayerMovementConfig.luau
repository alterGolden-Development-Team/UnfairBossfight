local Classes = require(script.Parent.Parent.Classes.ClassConfig)
return table.freeze({
  DashStaminaCost = Classes.Classes[Classes.Default].DashCost,
  DashDistance = 16,
  DashDuration = 0.34,
  DashImmunityDuration = Classes.DashImmunity,
  DashHoverHeight = 0.7,
  DashHoverLiftDuration = 0.065,
  DashHoverSettleDuration = 0.1,
})
