#!/usr/bin/env ruby

# Imports

require 'xcodeproj'

# Local Variables

project_path = ARGV[0]
project_name = File.basename(project_path, ".xcodeproj")
project = Xcodeproj::Project.open(project_path)

source_file = ARGV[1]
test_file = ARGV[2]

# Add Files

top_group = project.groups.find { |group| group.name == project_name }
sources_group = top_group.groups.find { |group| File.basename(group.path) == "Sources" }.groups.find { |group| File.basename(group.path) == project_name }
tests_group = top_group.groups.find { |group| File.basename(group.path) == "Tests" }.groups.find { |group| File.basename(group.path) == "#{project_name}Tests" }

source_file_ref = sources_group.new_file(source_file)
test_file_ref = tests_group.new_file(test_file)

project.native_targets.each do |target|
    if target.test_target_type?
        target.source_build_phase.add_file_reference(test_file_ref)
    else
        target.source_build_phase.add_file_reference(source_file_ref)
    end
end

project.save()
