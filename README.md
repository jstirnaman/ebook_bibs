# E-Book Bibs
A Ruby command-line script for local processing of vendor-supplied e-book records in MARC format.
Requires Ruby-Marc

		ebooks [OPTION] ... MARC-file

			-h, --help:
				show help

			--quiet
				run in quiet mode, suppressing output of counter and result messages
		
			--source 
				record source, publisher, or vendor.
		 
				One of: testingsource, accessmedicine, mdconsult, clinicalkey, henrystewarttalks, springerlink
					You can add your own name mappings.
			
			-t, --test:
				run in test mode against a set of MARC records (in tests/fixtures/).

			MARC file or piped input from stdin containing a string of MARC records.
				Examples, 
					From a file:
						ruby ebooks.rb AccessMedicine.mrc
						ruby ebooks.rb --marc AccessMedicine.mrc
					From stdin:
						curl http://www.accessusercenter.com/wp-content/uploads/2014/07/AccessMedicine.mrc | ruby ebooks.rb -s accessmedicine
