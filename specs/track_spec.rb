require "#{File.dirname(__FILE__)}/../lib/track"
require 'chronic'
require 'time'
require 'fileutils'


module TrackSpecHelpers
  def add_range(track, range, now = nil)
    return track.add_event(range.first, range.last, "***#{range.first}***")
  end
end

describe Track, "when adding events" do

  include TrackSpecHelpers

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
    now = Time.parse(DateTime.new(2030, 03, 17, 10, 39).to_s)
    track = Track.new("/dev/null")
    calendar = add_range(track, Chronic.parse("next saturday at 13:00", :guess => false, :now => now))
    calendar.events.first.dtstart.hour.should eql(13)
    calendar.events.first.dtend.hour.should eql(14)
  end

  it "should set a real start and end time for events specified for at least one full day" do
    now = Time.parse(DateTime.new(2030, 03, 17, 10, 39).to_s)
    track = Track.new("/dev/null")
    calendar = add_range(track,Chronic.parse("next saturday", :guess => false, :now => now), now)
    calendar.events.first.dtstart.year.should eql(2030)
    calendar.events.first.dtstart.hour.should eql(7)
    calendar.events.first.dtend.hour.should eql(23)
  end

# it "should set real start and end times even when the clocks change" do
#   now = Time.parse(DateTime.new(2030, 03, 27, 10, 39).to_s)
#   track = Track.new("/dev/null")
#   calendar = add_range(track,Chronic.parse("next monday", :guess => false, :now => now), now)
#   calendar.events.first.dtstart.hour.should eql(7)
#   calendar.events.first.dtend.hour.should eql(23)
# end

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

describe Track, "when viewing events" do

  include TrackSpecHelpers

  before :all do
    @track = Track.new("/dev/null")
    time = Time.now
    time = Time.parse(DateTime.new(2030, 03, 17, 10, 39).to_s)
    10.times do |count|
      add_range(@track, time...time+1, time)
      time += 14400
    end
  end

  it "should display the next five items if a date range is not supplied" do
    @track.view_events(nil, nil, 5).split("\n").length.should eql(5)
  end

  it "should display each line in the correct format" do
    @track.view_events(nil, nil, 5).should match(/^\w{3} \d{2} \w{3} \d{2}:\d{2} - \w{3} \d{2} \w{3} \d{2}:\d{2}   \*{3}.+\*{3}/)
  end

  it "should display all of the events for the supplied date range when no limit is specified" do
    start = DateTime.new(2030, 03, 17, 0, 0)
    finish = DateTime.new(2030, 03, 18, 0, 0)
    @track.view_events(start, finish).split("\n").length.should eql(4)
  end

  it "should display the maximum specified events for a date range" do
    start = DateTime.new(2030, 03, 17, 0, 0)
    finish = DateTime.new(2030, 03, 18, 0, 0)
    @track.view_events(start, finish, 2).split("\n").length.should eql(2)
  end

  it "should allow finding events by date range" do
    start = DateTime.new(2030, 03, 17, 0, 0)
    finish = DateTime.new(2030, 03, 18, 0, 0)
    events = @track.find_events_by_date(start, finish)
    events.first.dtstart.day.should eql(17)
    events.last.dtstart.day.should eql(17)
  end
end

describe Track, "when deleting events" do
  include TrackSpecHelpers

  before :all do
    @track = Track.new("/dev/null")
    time = Time.now
    time = Time.parse(DateTime.new(2030, 03, 17, 10, 39).to_s)
    10.times do |count|
      add_range(@track, time...time+1, time)
      time += 14400
    end
  end

  it "should delete all of the events for the supplied date range" do
    start = DateTime.new(2030, 03, 17, 0, 0)
    finish = DateTime.new(2030, 03, 18, 0, 0)
    @track.delete_events(start, finish).should eql(4)
    @track.view_events(start, finish).split("\n").length.should eql(0)
  end
end
