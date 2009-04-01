require 'date'
require 'time'
require 'icalendar'

class Track
  include Icalendar

  def initialize(calendar_file)
    @calendar_file = calendar_file
    calendar = Icalendar.parse(File.open(calendar_file)).first rescue nil
    @calendar = calendar || Calendar.new
    @calendar.product_id = "Track"
  end

  def add_event(range, subject)
    if range.first < Time.now
      raise "You cannot add events in the past"
    end

    range = set_real_start_and_end_dates(range)
    range = set_default_duration(range)

    event = Event.new
    event.start = DateTime.parse(range.first.to_s)
    event.end = DateTime.parse(range.last.to_s)
    event.summary = subject
    @calendar.add_event(event)

    purge_past_events
    sort_events
    write_to_file
    return @calendar
  end

  def view_events(range = nil, number_of_events = nil)
    output = ""
    if range
      events = find_events_by_date(range.first, range.last)
    else
      events = @calendar.events
    end
    unless number_of_events.nil?
      events = events[0...number_of_events]
    end
    events.each do |event|
      output << output_for_event(event)
    end
    purge_past_events
    write_to_file
    return output
  end

  def delete_events(range)
    deleted = 0
    find_events_by_date(range.first, range.last).each do |event|
      @calendar.events.delete(event)
      deleted += 1
    end
    purge_past_events
    write_to_file
    deleted
  end

  def find_events_by_date(start, finish)
    start = DateTime.new(start.year, start.month, start.day, start.hour, start.min)
    finish = DateTime.new(finish.year, finish.month, finish.day, finish.hour, finish.min)
    @calendar.events.find_all { |event| event.dtstart >= start and event.dtstart <= finish }
  end

  protected

  # Returns a string for outputting an event on a single 
  # line.
  def output_for_event(event)
    "#{event.dtstart.strftime('%a %d %b %H:%M')} - #{event.dtend.strftime('%a %d %b %H:%M')}   #{event.summary}\n"
  end

  def write_to_file
    File.open(@calendar_file, "w") { |file| file << @calendar.to_ical }
  end

  def sort_events
    @calendar.events.sort! { |x,y| x.dtstart <=> y.dtstart }
  end

  def purge_past_events
    now = DateTime.parse(Time.now.to_s)
    @calendar.events.delete_if { |event| event.dtstart <= now }
  end

  # When using full days, like "saturday" or "next week",
  # Chronic will set the start and end times to 00:00, but
  # my day really goes from 07:00 - 23:00.
  #
  # If the end of the event is not in the same TZ as the 
  # start, we assume that daylight savings changes occur 
  # in between.
  def set_real_start_and_end_dates(range)
    utc_difference = range.last.utc_offset - range.first.utc_offset
    if utc_difference != 0
      range = range.first...(range.last - utc_difference)
    end
    if range.first.hour == 0 and range.last.hour == 0
      range = (range.first + 25200)...(range.last - 3600)
    end
    range
  end

  # If we don't have an event duration, set a default of 
  # one hour.
  #
  # Since we're always requesting a date range from
  # Chronic, we'll actually get a range of 1 second when 
  # a single point in time is specified.
  def set_default_duration(range)
    if range.first == range.last or range.first == (range.last - 1)
      range = range.first...(range.last + 3600)
    end
    range
  end
end
