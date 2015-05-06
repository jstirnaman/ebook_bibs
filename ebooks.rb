require 'stringio'
require 'getoptlong'
require 'date'
require 'marc'

### You probably DON'T want to change these:
HOME = File.dirname(File.expand_path(__FILE__))
DATESTAMP =  DateTime.now.strftime('%Y%m%d')
OUT = "#{HOME}/data/out/"
LOGFILE = "#{HOME}/log/scn.log"
TEST_SOURCE = "testingsource"
###

### You probably DO want to change these:
# Normalized MARC Code assigned for your organization. 
# http://www.loc.gov/marc/organizations/org-search.php
MARC_CODE = "kum"
TEST_MARC_FIXTURE = "./tests/fixtures/vufindready.voyout.mrc.20140818.mrc"
SOURCES = {
  "testingsource" => "TESTING_SOURCE",
  "accessmedicine" => "Access_Medicine",
  "mdconsult" => "MD_Consult",
  "clinicalkey" => "Clinical_Key",
  "henrystewarttalks" => "Henry_Stewart_Talks",
  "springerlink" => "SpringerLink"
}

def resolve_source(source)
	m = SOURCES
	source = source.strip.gsub(/\W/i, "")
	m[source]
end

def set_link_text(record)
  if record['fields'].assoc('856')
    record = record.to_marchash
    link_text = 'Connect to electronic text'
    record['fields'].map! do |field|
			if field.values_at(0, 1, 2) == ['856', '4', '0']
				field[3].delete_if {|subfield| subfield[0] == 'z'}
				field[3] << ['z', link_text]
				field
			else
				field
			end
		end
		newrecord = MARC::Record.new_from_marchash(record)
  end  
end

def fix_clinicalkey_links(record)
  newrec = MARC::Record.new()
  newrec.leader = record.leader
  record.each do |field|
    # Omit 856 if subfield 3 is not "ClinicalKey"
    # or if subfield u has ".edu" in the domain
    # or the URL doesn't match "www.clinicalkey.com/" (including trailing slash).
    newrec.append(field) unless (field.tag == '856' && (field['3'] != 'ClinicalKey' || field['u'] =~ /https?:\/\/.*\.edu\// || (field['u'] =~ /https?:\/\/www\.clinicalkey\.com\//).nil?))
  end
 newrec
end

def add_holding_location(record)
  location = 'dyk.pubpcs'
  classifier = 'E-book'
  record.append(MARC::DataField.new('852', " ", " ", ['a', MARC_CODE], ['b', location], ['h', classifier]))
  record
end

def add_control_number(record)
  scn = record['001'].value
  record.append(MARC::DataField.new('035', " ", " ", ['a', "(#{MARC_CODE})#{DATESTAMP}#{scn}"] ))
  record
end

### Use source to treat records differently based on vendor.
def process_records(source, marc, test) 
  source = resolve_source(source) || source
  # Signify OCLC encoding for import script. 
  source == "Clinical_Key" ? extnsn = ".oclc" : extnsn = ".mrc" 
  marc_out = OUT + "kumc_ebooks_" + source + extnsn
  mode = test ? "Test" : "Normal"
  unless @quiet
    STDOUT.puts "Processing MARC from " + source + " with Mode: " + mode
  end
  reader = MARC::Reader.new(marc, :external_encoding => "UTF-8", :internal_encoding => "UTF-8", :invalid => :replace, :replace => "")
  writer = MARC::Writer.new(marc_out)
  logfile = File.open(LOGFILE, 'ab')
  counter = 0
  for record in reader
    # Do record enhancements
    newrecord = add_control_number(record)
    newrecord = add_holding_location(newrecord)
    if source == "Clinical_Key"
      newrecord = fix_clinicalkey_links(newrecord)
    end 
        
    # Re-sort the tags in the record after appending fields.
    newrecord.fields.sort_by!{|f| f.tag}
          
    begin
      writer.write(newrecord)
    rescue MARC::Exception => e
      STDERR.puts e.message
      STDERR.puts e.backtrace.inspect
    end   
    
    # Log 001 source control number
    logfile.puts record['001'].value
    counter += 1
    unless @quiet
      STDOUT.puts counter if (counter.modulo(100)).zero?
    end
  end
  writer.close
  logfile.close
  unless @quiet
		STDOUT.puts counter.to_s + " MARC records written to"
		STDOUT.puts marc_out
		STDOUT.puts "Source Control Numbers (001) logged to #{LOGFILE}"
  end
end

def do_commandline_opts
	opts = GetoptLong.new(
		[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
		[ '--test', '-t', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--source', '-s', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--marcfile', '-m', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--quiet', '-q', GetoptLong::OPTIONAL_ARGUMENT ]
	)

	test = nil
	source = nil
	marc = nil
	@quiet = nil
	opts.each do |opt, arg|
		case opt
			when '--help'
				STDOUT.puts <<-EOF
				ebooks [OPTION] ... MARC-file

				-h, --help:
					 show help

				--source AccessMedicine:
					 record source, publisher, or vendor. Used as value in MARC tag 710. 
					 One of: #{SOURCES.keys.join(', ')}
					 You can add your own name mappings.

				MARC-file or stream from stdin containing a string of MARC records.
					ex., 
						From a file:
							ruby ebooks.rb AccessMedicine.mrc
						From stdin:
							curl http://www.accessusercenter.com/wp-content/uploads/2014/07/AccessMedicine.mrc | ruby ebooks.rb -s accessmedicine

							EOF
			when '--source'
				source = arg
			when '--test'
				test = true
			when '--quiet'
			  @quiet = true      
		end
	end

	# ARGV should only have 0 or 1 members at this point
	if ARGF.argv.length != 1
		if test
			marc = TEST_MARC_FIXTURE
			source = TEST_SOURCE
    elsif source
      begin
        marc = StringIO.new(ARGF.read)
      rescue
        STDERR.puts "ebooks could not read input from stdin (try --help)."
        exit 1 
      end
    else
      STDERR.puts "ebooks --source is required when reading input from stdin."
      exit 1 
    end
  else
    source ||= ARGV[0].split('/').last.gsub(/\..*$/, '')
    marc = StringIO.new(ARGF.read)
  end

  process_records(source, marc, test)

end

do_commandline_opts
