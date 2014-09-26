require 'logger'
require 'mechanize'

# Methods for scraping the vendor's site. In most cases, we
# just use curl in the Linux shell whenever possible.
# curl or wget will be much simpler if it gets you by. 

HOME = File.dirname(File.expand_path(__FILE__))

def get_henry_stewart_talks
  # Use Mechanize to just return the correct download URL.
  agent = Mechanize.new
  agent.log = Logger.new "#{HOME}/log/mech.log"
  agent.log.level = Logger::INFO
  agent.user_agent_alias = "Mac Safari"
  agent.redirect_ok
	
	starting_uri = URI "http://hstalks.com/main/lib_marc.php"

	page = agent.get starting_uri
  # Return the link for the previous month's BLSC MARC download
  months_ago = Date.today << 2
  marc_uri = page.link_with(:href => /TBLSC.*#{months_ago.strftime('%b')}-#{months_ago.strftime('%Y')}.*zip/)
  parser = URI::Parser.new
	parser.join("http://" + page.uri.host, marc_uri.href) unless marc_uri.uri.host
end

begin
  $stdout.print get_henry_stewart_talks
end 
