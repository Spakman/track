# Redefine the definitions
#
class Chronic::RepeaterDayPortion < Chronic::Repeater #:nodoc:
  @@morning = (6 * 60 * 60)..(12 * 60 * 60) # 6am-12am
  @@afternoon = (13 * 60 * 60)..(17 * 60 * 60) # 1pm-6pm
  @@evening = (18 * 60 * 60)..(22 * 60 * 60) # 6pm-10pm
  @@night = (22 * 60 * 60)..(24 * 60 * 60) # 10pm-12pm
end
