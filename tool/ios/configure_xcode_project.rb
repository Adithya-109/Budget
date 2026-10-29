# frozen_string_literal: true

# Wires the native SplitBurn sources into ios/Runner.xcodeproj:
#   * SharedStorage/ (SQLite manager, schema, budget math) in Runner + widget
#   * QuickLogIntent.swift + ExpensePhraseParser.swift in Runner
#   * BalanceWidgetExtension app-extension target, embedded in Runner
#   * App Group entitlements, iOS 16 deployment target, -lsqlite3
#
# Idempotent: safe to re-run after `flutter create` regenerates files.
#   gem install xcodeproj && ruby tool/ios/configure_xcode_project.rb

require 'xcodeproj'

ROOT = File.expand_path('../..', __dir__)
PROJECT_PATH = File.join(ROOT, 'ios', 'Runner.xcodeproj')
DEPLOYMENT_TARGET = '16.0'
WIDGET_NAME = 'BalanceWidgetExtension'
WIDGET_BUNDLE_ID = 'com.splitburn.app.BalanceWidget'

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target missing'
runner_tests = project.targets.find { |t| t.name == 'RunnerTests' }

def group_for(project, name)
  project.main_group.children.find { |c| c.display_name == name && c.isa == 'PBXGroup' } ||
    project.main_group.new_group(name, name)
end

def file_ref(group, path)
  group.files.find { |f| f.path == path } || group.new_reference(path)
end

def add_source(target, ref)
  return if target.source_build_phase.files_references.include?(ref)

  target.source_build_phase.add_file_reference(ref)
end

# --- Shared sources --------------------------------------------------------
shared_group = group_for(project, 'SharedStorage')
shared_refs = %w[SharedSQLiteManager.swift FinanceSchema.swift BudgetMath.swift].map do |name|
  file_ref(shared_group, name)
end

runner_group = project.main_group.children.find { |c| c.display_name == 'Runner' }
runner_refs = %w[QuickLogIntent.swift ExpensePhraseParser.swift].map { |name| file_ref(runner_group, name) }
file_ref(runner_group, 'Runner.entitlements')

(shared_refs + runner_refs).each { |ref| add_source(runner, ref) }

# --- Widget extension target -------------------------------------------------
widget_group = group_for(project, WIDGET_NAME)
widget_swift = file_ref(widget_group, 'BalanceWidget.swift')
file_ref(widget_group, 'Info.plist')
file_ref(widget_group, "#{WIDGET_NAME}.entitlements")
widget_xcconfig = file_ref(widget_group, 'BalanceWidget.xcconfig')

widget = project.targets.find { |t| t.name == WIDGET_NAME }
unless widget
  widget = project.new_target(:app_extension, WIDGET_NAME, :ios, DEPLOYMENT_TARGET, nil, :swift)
  widget.product_reference.name = "#{WIDGET_NAME}.appex"
end

([widget_swift] + shared_refs).each { |ref| add_source(widget, ref) }

# Swift auto-links WidgetKit / SwiftUI / Foundation on import. Drop the
# framework references xcodeproj adds, which pin a specific SDK version path.
widget.frameworks_build_phase.files.to_a.each do |build_file|
  ref = build_file.file_ref
  build_file.remove_from_project
  ref.remove_from_project if ref && ref.build_files.empty?
end
frameworks_group = project.frameworks_group
frameworks_group.recursive_children.select { |c| c.isa == 'PBXGroup' && c.children.empty? }.each(&:remove_from_project)
frameworks_group.remove_from_project if frameworks_group.children.empty?

# Build configurations: make sure the widget has one per project
# configuration (Debug / Release / Profile).
project.build_configurations.each do |project_config|
  next if widget.build_configuration_list[project_config.name]

  config = widget.add_build_configuration(project_config.name, project_config.name == 'Debug' ? :debug : :release)
  config.build_settings.merge!(widget.build_configuration_list['Release'].build_settings) if project_config.name != 'Debug'
end

widget.build_configurations.each do |config|
  config.base_configuration_reference = widget_xcconfig
  config.build_settings.merge!(
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'PRODUCT_BUNDLE_IDENTIFIER' => WIDGET_BUNDLE_ID,
    'INFOPLIST_FILE' => "#{WIDGET_NAME}/Info.plist",
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'CODE_SIGN_ENTITLEMENTS' => "#{WIDGET_NAME}/#{WIDGET_NAME}.entitlements",
    'CODE_SIGN_STYLE' => 'Automatic',
    'IPHONEOS_DEPLOYMENT_TARGET' => DEPLOYMENT_TARGET,
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SKIP_INSTALL' => 'YES',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks'],
    'OTHER_LDFLAGS' => ['$(inherited)', '-lsqlite3'],
    'SWIFT_EMIT_LOC_STRINGS' => 'YES'
  )
  if config.name == 'Debug'
    config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
  end
end

# --- Runner: entitlements, deployment target, embed the extension -----------
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  flags = Array(config.build_settings['OTHER_LDFLAGS'] || ['$(inherited)'])
  flags = ['$(inherited)'] + flags unless flags.include?('$(inherited)')
  flags << '-lsqlite3' unless flags.include?('-lsqlite3')
  config.build_settings['OTHER_LDFLAGS'] = flags
end
project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
end
runner_tests&.build_configurations&.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
end

# --- Simulator architecture --------------------------------------------------
# Google ML Kit (receipt scanning) ships no arm64-simulator slice, so on Apple
# Silicon the simulator build runs as x86_64 under Rosetta. ios/Podfile applies
# the same exclusion to every pod. i386 repeats Flutter's own exclusion, which
# a target-level value would otherwise override.
[runner, runner_tests, widget].compact.each do |target|
  target.build_configurations.each do |config|
    config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64 i386'
  end
end

runner.add_dependency(widget) unless runner.dependencies.any? { |d| d.target == widget }

embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
unless embed
  embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed.name = 'Embed Foundation Extensions'
  embed.symbol_dst_subfolder_spec = :plug_ins
  embed.dst_path = ''
  # Must run before Flutter's "Thin Binary" script, or Xcode reports a
  # dependency cycle in the Runner target.
  thin_binary = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
  if thin_binary
    runner.build_phases.insert(thin_binary, embed)
  else
    runner.build_phases << embed
  end
end
unless embed.files_references.include?(widget.product_reference)
  build_file = embed.add_file_reference(widget.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save
puts "Configured #{PROJECT_PATH}"
