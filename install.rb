#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'fileutils'

# constants

VERSION = '0.1.0'
DOT_PREFIX = 'dot_'

DOMAINS = { user_direcory: '~' }.freeze

# option parsing

$options = {}

option_parser = OptionParser.new do |opts|
  script_file = File.basename($PROGRAM_NAME)
  opts.banner = "Usage: #{script_file} [$options] files or directories"

  opts.on('--version', "Prints the version of #{script_file}") do
    puts "Version: #{VERSION}"
    exit
  end

  $options[:verbose] = false
  opts.on('-v', '--verbose', "Prints the version of #{script_file}") do
    $options[:verbose] = true
  end

  $options[:dry_run] = false
  opts.on('-n', '--dry-run', 'Shows what would be installed') do
    $options[:dry_run] = true
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end

# methods

def install_file(file, domain = "user_direcory")
  puts "install_file: #{file}" if $options[:verbose]

  source_file = Pathname.new(file).realpath
  puts "Source file: #{source_file}" if $options[:verbose]

  transformed_file = file.delete_prefix!(DOT_PREFIX).prepend('.') if file.start_with?(DOT_PREFIX)

  install_path = File.join(Dir.home, transformed_file)
  puts "Install path: #{install_path}" if $options[:verbose]

  if File.exist?(install_path)
    real_path = Pathname.new(install_path).realpath
    backup_file_path = real_path.to_s.concat('.bak')

    puts "Backup file #{real_path} to #{backup_file_path}" if $options[:verbose]
    File.rename(real_path, backup_file_path)
  end

  puts "Copy file #{source_file} to #{install_path}" if $options[:verbose]
  FileUtils.cp(source_file, install_path)
end

def process_files(directory)
  puts "process_files: #{directory}" if $options[:verbose]

  cwd = Dir.getwd
  Dir.chdir(directory)

  Dir.glob('**/*') do |file|
    puts "File: #{file}" if $options[:verbose]

    install_file(file)
  end

  Dir.chdir(cwd)
end

if __FILE__ == $PROGRAM_NAME
  option_parser.parse!
  abort(option_parser.help) if ARGV.empty?

  puts 'Start'

  ARGV.each do |file|
    pathname = Pathname.new(file)
    unless pathname.exist?
      warn "Error: no such file or directory #{pathname}"
      next
    end

    real_path = pathname.realpath
    puts "Processing: #{real_path}"
    if real_path.directory?
      process_files(real_path)
    else
      process_file(real_path)
    end
  end
end

puts 'End'
