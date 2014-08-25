require 'rubygems'
require 'bundler/setup'
require 'getoptlong'
require 'marc'
TEST_MARC_FIXTURE = "./tests/fixtures/vufindready.voyout.mrc.20140818.mrc"
TEST_SOURCE = "testingsource"
@records = []

def resolve_source(source)
m = {
  "testingsource" => "TESTING SOURCE",
  "accessmedicine" => "Access Medicine",
  "mdconsult" => "MD Consult",
  "clinicalkey" => "Clinical Key",
  "henrystewarttalks" => "Henry Stewart Talks",
  "springerlink" => "SpringLink"
}
source = source.strip.gsub(/\W/i, "")
m[source]
end

# Count MARC records in file
# marc is a string with a bunch of records in it.
# Construct a new marc reader instance
def count_records
reader = MARC::Reader.new(@marc)
i = 0
for record in reader
  i += 1
end
puts "marc contains " + i.to_s + " records"
end

# Search records for a pattern
def title_matches(search_pattern)
reader = MARC::Reader.new(@marc)
record_array = []
for record in reader
  if record['245'] =~ /#{search_pattern}/
    record_array << record
  end
end
@records = record_array
end

def location_matches(search_pattern)
reader = MARC::Reader.new(@marc)
record_array = []
for record in reader
  if record['852'] =~ /#{search_pattern}/
    record_array << record
  end
end
@records = record_array
end

def control_007_matches(search_pattern)
reader = MARC::Reader.new(@marc)
record_array = []
for record in reader
  if record['007'] =~ /#{search_pattern}/ 
    record_array << record
  end
end
@records = record_array
end

def leader_matches(search_pattern)
reader = MARC::Reader.new(@marc)
record_array = []
for record in reader
  if record['leader'] =~ /#{search_pattern}/ 
    record_array << record
  end
end
@records = record_array
end

def set_link_text(newrecord)
  link_text = 'Connect to electronic text'
  newrecord['fields'].map! do |field|
    if field.values_at(0, 1, 2) == ['856', '4', '0']
      field[3].delete_if {|subfield| subfield[0] == 'z'}
      field[3] << ['z', link_text]
      field
    else
      field
    end
  end
  newrecord
end

def process_records(source, marc, test)
  source = resolve_source(source)
  mode = test ? "Test" : "Normal"
  marc_out = "ebooks_#{source.gsub(/\s/, '_')}.marc"
  STDOUT.puts "Marcfile: " + marc + " from " + source + " Mode: " + mode
  reader = MARC::Reader.new(marc)
  writer = MARC::Writer.new(marc_out)
  counter = 0
  for record in reader
    newrecord = record.to_marchash
    if newrecord['fields'].assoc('856') 
      newrecord = set_link_text(newrecord)
    end
    writer.write(MARC::Record.new_from_marchash(newrecord))
    counter += 1
    STDOUT.puts counter if (counter.modulo(100)).zero?  
  end
  writer.close
  STDOUT.puts counter.to_s + " MARC records written to " + marc_out
end

def do_commandline_opts
opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--test', '-t', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--source', '-s', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--marcfile', '-m', GetoptLong::OPTIONAL_ARGUMENT ]
)

test = nil
source = nil
marc = nil
opts.each do |opt, arg|
  case opt
    when '--help'
      STDOUT.puts <<-EOF
ebooks [OPTION] ... MARC-file

-h, --help:
   show help

--source AccessMedicine:
   record source, publisher, or vendor. Used as value in MARC tag 710.

MARC-file
   file containing a string of MARC records.

      EOF
    when '--source'
      source = arg
    when '--test'
      test = true      
  end
end

if ARGV.length != 1
  if test
    marc = TEST_MARC_FIXTURE
    source = TEST_SOURCE
  else
    STDERR.puts "Missing file argument (try --help)"
    exit 0
  end
else
  marc = ARGV.shift
end

process_records(source, marc, test)

end

do_commandline_opts


