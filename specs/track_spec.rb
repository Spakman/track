require "#{File.dirname(__FILE__)}/../lib/track"
require 'chronic'
require 'time'
require 'fileutils'

describe Track, "when adding an event" do

  def add_range(track, range, now = nil)
    options = { :start => range.first, :end => range.last, :guess => false, :now => now }
    return track.add_event(options)
  end

  it "should sort the events chronologically" do
    now = Time.parse(DateTime.new(2030, 03, 17, 10, 39).to_s)
    track = Track.new("/dev/null")
    add_range(track,Chronic.parse("next saturday", :guess => false, :now => now), now)
    add_range(track, Chronic.parse("next monday", :guess => false, :now => now), now)
    calendar = add_range(track, Chronic.parse("next sunday", :guess => false, :now => now), now)

    calendar.events.first.dtstart.day.should eql(18)
    calendar.events.last.dtstart.day.should eql(24)
  end

  it "should set a default duration if one is not supplied" do
    track = Track.new("/dev/null")
    calendar = add_range(track, Chronic.parse("next saturday at 13:00", :guess => false))
    calendar.events.first.dtstart.hour.should eql(13)
    calendar.events.first.dtend.hour.should eql(14)
  end

  it "should set a real start and end time for events specified for at least one full day" do
    now = Time.parse(DateTime.new(2030, 03, 17, 10, 39).to_s)
    track = Track.new("/dev/null")
    calendar = add_range(track,Chronic.parse("next saturday", :guess => false, :now => now), now)
    calendar.events.first.dtstart.hour.should eql(7)
    calendar.events.first.dtend.hour.should eql(23)
  end

  it "should set real start and end times even when the clocks change"

  it "should remove events that have passed after adding the new one" do
    now = Time.now + 1 # this is fragile
    track = Track.new("/dev/null")
    add_range(track, now...now)
    calendar = add_range(track, Chronic.parse("next week", :guess => false))
    calendar.events.length.should eql(1)
  end

  it "should raise an exception when trying to add an event in the past" do
    options = { :date => Chronic.parse("last saturday", :guess => false) }
    track = Track.new("/dev/null")
    lambda { track.add_event(options) }.should raise_error
  end

  it "should write to the filesystem" do
    calendar = "#{File.dirname(__FILE__)}/spec_calendar"
    track = Track.new(calendar)
    add_range(track, Chronic.parse("next week", :guess => false))
    `wc -l #{calendar}`.should_not equal(0)
    FileUtils.rm(calendar)
  end

end
