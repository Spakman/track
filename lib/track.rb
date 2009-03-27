require 'date'
require 'icalendar'

class Track
  include Icalendar

  def initialize(calendar_file)
    @calendar_file = calendar_file
    calendar = Icalendar.parse(File.open(calendar_file)).first rescue nil
    @calendar = calendar || Calendar.new
    @calendar.product_id = "Track"
  end

  def add_event(options)
    if options[:start] < Time.now
      raise "You cannot add events in the past"
    end

    set_real_start_and_end_dates(options)
    set_default_duration(options)

    start = options[:start]
    finish = options[:end]
    @calendar.event do
      dtstart  DateTime.new(start.year, start.month, start.day, start.hour, start.min)
      dtend    DateTime.new(finish.year, finish.month, finish.day, finish.hour, finish.min)
      summary  options[:subject]
      klass    "PRIVATE"
    end

    purge_past_events
    sort_events
    write_to_file
    return @calendar
  end

  def view_events(options)
    purge_past_events
    @calendar.events[0...options[:number_of_events]].each do |event|
      start_day = event.dtstart.strftime("%a")
      end_day = event.dtend.strftime("%a")
      puts "#{start_day} #{event.dtstart.strftime('%d, %H:%M')} - #{end_day} #{event.dtend.strftime('%H:%M')}   #{event.summary}"
    end
    write_to_file
  end

  protected

  def write_to_file
    File.open(@calendar_file, "w") { |file| file << @calendar.to_ical }
  end

  def sort_events
    @calendar.events.sort! { |x,y| x.dtstart <=> y.dtstart }
  end

  def purge_past_events
    time_now = Time.now
    now = DateTime.new(time_now.year, time_now.month, time_now.day, time_now.hour, time_now.min)
    @calendar.events.delete_if { |event| event.dtend <= now }
  end

  # When using full days, like "saturday" or "next week",
  # Chronic will set the start and end times to 00:00, but
  # my day really goes from 07:00 - 23:00.
  def set_real_start_and_end_dates(options)
    if options[:start].hour == 0 and options[:end].hour == 0
      options[:start] += 25200 # +7 hours
      options[:end] -= 3600 # -1 hour
    end
  end

  # If we don't have an event duration, set a default of 
  # one hour.
  #
  # Since we're always requesting a date range from
  # Chronic, we'll actually get a range of 1 second when 
  # a single point in time is specified.
  def set_default_duration(options)
    if options[:start] == options[:end] - 1
      options[:end] += 3600 # +1 hour
    end
  end
end
