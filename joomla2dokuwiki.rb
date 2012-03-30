#!/usr/bin/env ruby
# encoding: utf-8
#
# Script that converts a dump of the joomla content-table (csv export)
# into Dokuwiki page files
#
# Author: Philipp Böhm
# License: GPLv3
#

def replace_html_with_dw_syntax(html)

  if html
    # <span style="font-family: courier new,courier;">apt-get upgrade</span>
    html.gsub!(/<span.style=.*?courier.*?>(.*?)<\/span>/, '\'\'\1\'\'')

  end
  html
end

def fix_show_commands(line)
  if line.match(/^\'\'(.*)\'\'$/)
    line = "  #{$1.strip}"
    line.gsub!(/\'/, '')
  end
  line
end

require 'optparse'
require 'fileutils'
require 'csv'
require 'sanitize'

options = { :outputdir => File.join(File.dirname(__FILE__), 'dw_data')}

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [Options]"

  opts.on( "-i", "--input-file=STRING", String,
           "Joomla csv dump of content table") do |opt|
    options[:csvfile] = opt
  end

  opts.on( "-o", "--outputdir=STRING", String,
           "Path to directory where the files will be created") do |opt|
    options[:outputdir] = opt
  end

end.parse!

fail "csv file needed with [ -i ... ]" unless options[:csvfile]
fail "csv file does not exist" unless File.file? options[:csvfile]

FileUtils.mkdir(options[:outputdir]) unless File.directory? options[:outputdir]

CSV.foreach(options[:csvfile]) do |row|
  title = row[1]
  cleaned_title = row[2]

  introhtml = replace_html_with_dw_syntax(row[4])
  introtext = Sanitize.clean(introhtml).strip

  fullhtml = row[5]
  next unless fullhtml

  fullhtml = replace_html_with_dw_syntax(row[5])
  fulltext = Sanitize.clean(row[5])

  file = File.join( options[:outputdir], cleaned_title + ".txt" )

  p file

  p "#{title} - #{cleaned_title}"

  open(file, "w") do |file|
    file.write( "====== %s ======\n\n" % title )

    if introtext && introtext.match(/\w+/)
      introtext.lines.each do |line|
        file.write("#{line.strip}\n")
      end
      file.write("\n~~READMORE~~\n")
    end
    fulltext.lines.each do |line|
      file.write("#{fix_show_commands(line.strip)}\n")
    end
  end
end
