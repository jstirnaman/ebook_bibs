require 'logger'
require 'mechanize'

# Methods for scraping the vendor's site. In most cases, we
# just use curl in the Linux shell whenever possible.
# curl or wget will be much simpler if it gets you by, 
# but you can add additional sources here if you need it.

HOME = File.dirname(File.expand_path(__FILE__))

# Configure your own OCLC authorization here:
OCLC_AUTH = "xxx-xxx-xxx"
OCLC_AUTH_PWD = "PASSWORD"

def get_clinical_key
  marc = ''
  agent = Mechanize.new
  agent.log = Logger.new "#{HOME}/log/mech.log"
  agent.log.level = Logger::INFO
  agent.user_agent_alias = "Mac Safari"
  agent.redirect_ok
	
	# Get records from OCLC's Collection Sets service.
	uri = URI "http://psw.oclc.org/list.aspx?set=wcs"
	agent.add_auth(uri, OCLC_AUTH, OCLC_AUTH_PWD)

	page = agent.get uri
	login_form = page.form_with :name => "_ctl0"
	login_form.field_with(:name => "txtUsername").value = OCLC_AUTH
	login_form.field_with(:name => "txtPassword").value = OCLC_AUTH_PWD

	result = agent.submit(login_form, login_form.button_with(:name => "btnSubmit"))
	result.frames_with(:name => "mainFrame").each do |frame|
		frame.content.links_with(:href => /download\.aspx/).each do |link|
			marc = agent.get(link.href).body
		end
	end
  @marc = marc
end
begin
  get_clinical_key
  $stdout.print @marc
rescue Errno::EPIPE
  exit(74)
end 
