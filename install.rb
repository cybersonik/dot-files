#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require "fileutils"

# constants

VERSION = "0.1.0"
DOT_PREFIX = "dot_"

DOMAINS = {
              user_directory: Dir.home,
              terminal_profiles: "~/Library/"
          }.freeze

# option parsing

$options = {}

option_parser =
  OptionParser.new do |opts|
    script_file = File.basename($PROGRAM_NAME)
    opts.banner = "Usage: #{script_file} [$options] files or directories"

    opts.on("--version", "Prints the version of #{script_file}") do
      puts "Version: #{VERSION}"
      exit
    end

    $options[:domain] = ""
    opts.on("-u","--user","Specifies files should be installed in the user directory (~)") do
      $options[:domain] = :user_directory
    end
    opts.on("-t","--terminal","Specifies files should be installed in the Terminal Profiles directory (~)") do
      $options[:domain] = :terminal_profiles
    end

    $options[:verbose] = false
    opts.on("-v", "--verbose", "Prints the version of #{script_file}") do
      $options[:verbose] = true
    end

    $options[:dry_run] = false
    opts.on("-n", "--dry-run", "Shows what would be installed") do
      $options[:dry_run] = true
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end


# methods

def install_directory(relative_directory, domain = :user_directory)
  puts ">> Start install_directory: #{relative_directory}" if $options[:verbose]

  cwd = Dir.getwd
  Dir.chdir(relative_directory)

  Dir.glob("**/*") do |file|
    install_file = Pathname.new(file).realpath
    puts ">> File: #{install_file}" if $options[:verbose]

    relative_file = File.join(relative_directory, file)
    install_file(file,  $options[:domain])
  end

  Dir.chdir(cwd)

  puts ">> End install_directory: #{relative_directory}" if $options[:verbose]
end

def install_file(relative_file, domain = :user_directory)
  puts ">> Start install_file: #{relative_file}" if $options[:verbose]

  source_file = Pathname.new(relative_file).realpath
  puts ">> Source file: #{source_file}" if $options[:verbose]

  pathname = Pathname.new(relative_file)
  transformed_pathname = []
  pathname_enumerator = pathname.each_filename
  
  pathname_enumerator.each_with_index do |component, index|
    if index == 0 and component == domain.to_s
      next
    elsif component.start_with?(DOT_PREFIX)
      transformed_pathname.append(component.delete_prefix(DOT_PREFIX).prepend("."))
    else
      transformed_pathname.append(component)
    end
  end
  
  install_root = DOMAINS[domain]
  transformed_pathname.prepend(install_root)
  destination_file = File.join(transformed_pathname)
  puts ">> Destination file: #{destination_file}" if $options[:verbose]

  if File.directory?(source_file)
    source_directory = source_file
    puts "Copying directory #{source_directory} to #{destination_file}"

    if !File.exist?(source_directory)
      puts "Making directory #{source_directory} at #{destination_file}"
      FileUtils.mkdir(source_directory) if !$options[:dry_run]
    end

    install_directory(relative_file,  $options[:domain])
  else
    if File.exist?(destination_file)
      previous_file = Pathname.new(destination_file).realpath
      backup_suffix = Time.now.strftime(".%y%m%d-%k%M%S.bak")
      backup_file = previous_file.to_s.concat(backup_suffix)
  
      puts "Backing up file #{previous_file} to #{backup_file}"
      File.rename(previous_file, backup_file) if !$options[:dry_run]
    end

    puts "Copying file #{source_file} to #{destination_file}"
    FileUtils.copy_file(source_file, destination_file) if !$options[:dry_run]  
  end

  puts ">> End install_file: #{relative_file}" if $options[:verbose]
end

def process_files(directory)
  puts "> Start process_files: #{directory}" if $options[:verbose]

  cwd = Dir.getwd
  Dir.chdir(directory)

  Dir.glob("**/*") do |file|
    puts "> Process file: #{file}" if $options[:verbose]

    install_file(file,  $options[:domain])
  end

  Dir.chdir(cwd)

  puts "> End process_files: #{directory}" if $options[:verbose]
end

def process_file(file)
  puts "> Start process_file: #{file}" if $options[:verbose]

  puts "> Process file: #{file}" if $options[:verbose]
  install_file(file,  $options[:domain])

  puts "> End process_file: #{file}" if $options[:verbose]
end

if __FILE__ == $PROGRAM_NAME
  option_parser.parse!
  abort(option_parser.help) if ARGV.empty? or $options[:domain] == ""

  script = Pathname.new($PROGRAM_NAME).basename.to_s

  puts "Start #{script} script" if $options[:verbose]

  ARGV.each do |file|
    pathname = Pathname.new(file)
    unless pathname.exist?
      warn "Error: no such file or directory #{file}"
      next
    end

    install_root = DOMAINS[$options[:domain]]
    if pathname.directory? 
      puts "Installing files from #{file} to #{install_root}"
      process_files(file)
    else
      puts "Installing file #{file} to #{install_root}"
      process_file(file)
    end
  end

  puts "End #{script} script" if $options[:verbose]

end
