require 'date'
require 'builder'

# CalendarIterator

module CalendarIterator
  VERSION = 0.1
  
  # Provides a simple iteration over the days of a month at calendar
  # this way you can fast create full customized calendars by simple
  # iterating over the days
  #
  # Each item of this list is an Date object (supporting everything that
  # a regular Rails Date object supports) with some extensions
  # (see DateExtensions for the list)
  #
  # The following options are accepted by calendar_iterate:
  #   :month => 9    # month of calendar
  #   :year  => 2009 # year of calenadar
  #
  # If you don't use a block, calendar_iterate will return a list with
  # the month calendar days. this list contains the full weeks of the
  # calendar (including days of past month and next month if they are
  # needed to complete the weeks of calendar)
  # If you give a block, calendar_iterate will generate the <tr> and
  # <td> tags to create the calendar table
  #
  # Examples of usage:
  #
  # 1. creating a simple calendar
  #   <table>
  #     <tbody>
  #       <% calendar_iterate do |d| %>
  #         <%= d %>
  #       <% end %>
  #     </tbody>
  #   </table>
  #
  # 2. using links at calendar days
  #   <table>
  #     <tbody>
  #       <% calendar_iterate do |d| %>
  #         <%= link_to d, events_path(:day => d.mday) %>
  #       <% end %>
  #     </tbody>
  #   </table>
  #
  # 3. using a full customized <tr> and <td> tags
  #   <table>
  #     <tbody>
  #       <% calendar_iterate.each_week do |w| %>
  #       <tr class="some_class">
  #         <% w.each do |d| %>
  #           <td class="cell_class"><%= d %></td>
  #         <% end %>
  #       </tr>
  #       <% end %>
  #     </tbody>
  #   </table>
  
  def calendar_iterate(options = {}, &block)
    options = {
      :month => Date.current.month,
      :year => Date.current.year
    }.merge(options)
    
    first = Date.new(options[:year], options[:month], 1)
    last = first.end_of_month
    
    days = []
    
    first.wday.times do |i|
      days << first - (first.wday - i)
    end
    
    (first..last).each do |i|
      days << i
    end
    
    wday = last.wday
    
    while wday < 6
      wday += 1
      days << days.last.tomorrow
    end
    
    days.each do |d|
      meta = class << d; self; end
      
      meta.send :define_method, :calendar_month do
        options[:month]
      end
      
      d.extend DateExtensions
    end
    
    def days.each_week(&block)
      self.in_groups_of 7, &block
    end
    
    if block
      buffer = ""
      
      days.each_week do |g|
        buffer += "<tr>"
        
        g.each do |d|
          buffer += "<td>#{capture(d, &block)}</td>"
        end
        
        buffer += "</tr>";
      end
      
      concat(buffer)
    end
    
    days
  end
  
  module DateExtensions
    # Check if current day is a weekend day
    def weekend?
      [0, 6].include? self.wday
    end
    
    # Check if current day is from current month (it can be from other months
    # felling the calendar week)
    def current_month?
      self.month == calendar_month
    end
    
    # Override Date default to_s to output current day
    def to_s
      mday.to_s
    end
  end
end
