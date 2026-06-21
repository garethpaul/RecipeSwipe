#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'shellwords'
require 'tmpdir'
require 'timeout'

ROOT = File.expand_path('..', __dir__)

def assert_default_time_bounds
  test_runner = File.read(File.join(ROOT, 'scripts/xcode-test.sh'))
  expected = 'SIMCTL_TIMEOUT="${RECIPESWIPE_SIMCTL_TIMEOUT:-60}"'
  raise 'simulator discovery default must remain bounded at 60 seconds' unless test_runner.include?(expected)
end
RunResult = Struct.new(:status, :elapsed, :output, :externally_timed_out, keyword_init: true)

def alive?(pid)
  Process.kill(0, pid)
  true
rescue Errno::ESRCH
  false
end

def terminate_group(pid)
  Process.kill('TERM', -pid)
rescue Errno::ESRCH
  nil
ensure
  begin
    Timeout.timeout(1) { Process.wait(pid) }
  rescue Errno::ECHILD
    nil
  rescue Timeout::Error
    nil
  end
  begin
    Process.kill('KILL', -pid)
  rescue Errno::ESRCH
    nil
  end
  begin
    Process.wait(pid)
  rescue Errno::ECHILD
    nil
  end
end

def spawn_runner(action, env, stdout_path, stderr_path)
  case action
  when :build
    Process.spawn(env, 'bash', 'scripts/xcode-build.sh', chdir: ROOT, out: stdout_path, err: stderr_path, pgroup: true) # nosemgrep: ruby.lang.security.dangerous-exec.dangerous-exec -- executable and script are fixed test constants
  when :test
    Process.spawn(env, 'bash', 'scripts/xcode-test.sh', chdir: ROOT, out: stdout_path, err: stderr_path, pgroup: true) # nosemgrep: ruby.lang.security.dangerous-exec.dangerous-exec -- executable and script are fixed test constants
  else
    raise "unknown runner action: #{action}"
  end
end

def run_script(action, env, directory, label, guard_seconds: 8)
  stdout_path = File.join(directory, "#{label}.stdout")
  stderr_path = File.join(directory, "#{label}.stderr")
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  pid = spawn_runner(action, env, stdout_path, stderr_path)
  status = nil
  externally_timed_out = false

  begin
    Timeout.timeout(guard_seconds) { _, status = Process.wait2(pid) }
  rescue Timeout::Error
    externally_timed_out = true
    terminate_group(pid)
  end

  RunResult.new(
    status: status,
    elapsed: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started,
    output: [File.read(stdout_path), File.read(stderr_path)].join,
    externally_timed_out: externally_timed_out
  )
end

def write_executable(path, content)
  File.write(path, content)
  File.chmod(0o755, path)
end

def assert_watchdog_reaps_success_descendant
  Dir.mktmpdir('recipeswipe-watchdog-success-descendant') do |directory|
    child = File.join(directory, 'child')
    parent_pid = File.join(directory, 'parent.pid')
    descendant_pid = File.join(directory, 'descendant.pid')
    write_executable(child, <<~SH)
      #!/bin/sh
      printf '%s\n' "$$" > #{Shellwords.escape(parent_pid)}
      sh -c 'trap "" HUP INT TERM; sleep 600' &
      printf '%s\n' "$!" > #{Shellwords.escape(descendant_pid)}
      exit 0
    SH
    env = ENV.to_h.merge(
      'RECIPESWIPE_TIMEOUT_TERM_GRACE' => '0.2',
      'RECIPESWIPE_TIMEOUT_KILL_GRACE' => '0.2'
    )
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    wrapper_pid = Process.spawn(
      env,
      'ruby',
      '--disable-gems',
      'scripts/run-with-timeout.rb',
      '10',
      'success descendant',
      child,
      chdir: ROOT,
      out: File::NULL,
      err: File::NULL
    ) # nosemgrep: ruby.lang.security.dangerous-exec.dangerous-exec -- executable and watchdog path are fixed test constants
    _, status = Timeout.timeout(4) { Process.wait2(wrapper_pid) }
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    raise 'watchdog did not preserve successful child status' unless status.success?
    raise "watchdog success cleanup was not prompt (#{elapsed.round(2)}s)" if elapsed >= 3
    assert_no_processes([parent_pid, descendant_pid], child)
  ensure
    if File.exist?(parent_pid)
      process_group = Integer(File.read(parent_pid), exception: false)
      begin
        Process.kill('KILL', -process_group) if process_group
      rescue Errno::ESRCH
        nil
      end
    end
  end
end

def assert_watchdog_treats_eperm_probe_as_alive
  Dir.mktmpdir('recipeswipe-watchdog-eperm-probe') do |directory|
    child = File.join(directory, 'child')
    shim = File.join(directory, 'process-kill-eperm.rb')
    descendant_pid = File.join(directory, 'descendant.pid')
    eperm_probe_marker = File.join(directory, 'eperm-probe.marker')
    write_executable(child, <<~SH)
      #!/bin/sh
      sh -c 'trap "" HUP INT TERM; sleep 600' &
      printf '%s\n' "$!" > #{Shellwords.escape(descendant_pid)}
      exit 0
    SH
    File.write(shim, <<~'RUBY')
      module Process
        class << self
          alias recipeswipe_original_kill kill

          def kill(signal, pid)
            if signal == 0 && pid.negative?
              File.write(ENV.fetch('RECIPESWIPE_EPERM_PROBE_MARKER'), pid.to_s)
              raise Errno::EPERM
            end

            recipeswipe_original_kill(signal, pid)
          end
        end
      end
    RUBY
    env = ENV.to_h.merge(
      'RECIPESWIPE_TIMEOUT_TERM_GRACE' => '0.2',
      'RECIPESWIPE_TIMEOUT_KILL_GRACE' => '0.2',
      'RECIPESWIPE_EPERM_PROBE_MARKER' => eperm_probe_marker,
      'RUBYOPT' => [ENV['RUBYOPT'], "-r#{shim}"].compact.join(' ')
    )
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    wrapper_pid = Process.spawn(
      env,
      'ruby',
      '--disable-gems',
      'scripts/run-with-timeout.rb',
      '10',
      'EPERM probe descendant',
      child,
      chdir: ROOT,
      out: File::NULL,
      err: File::NULL
    ) # nosemgrep: ruby.lang.security.dangerous-exec.dangerous-exec -- executable, shim, and watchdog paths are fixed test fixtures
    _, status = Timeout.timeout(4) { Process.wait2(wrapper_pid) }
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    raise 'watchdog did not preserve successful child status after EPERM probe' unless status.success?
    raise "watchdog EPERM cleanup was not prompt (#{elapsed.round(2)}s)" if elapsed >= 3
    raise 'watchdog EPERM process-group probe was not exercised' unless File.exist?(eperm_probe_marker)
    assert_no_processes([descendant_pid], child)
  end
end

def assert_watchdog_rejects_unbounded_durations
  invalid_configurations = [
    [{}, 'Infinity', 'timeout must be finite and positive'],
    [{}, 'NaN', 'timeout must be finite and positive'],
    [{}, '0', 'timeout must be finite and positive'],
    [{ 'RECIPESWIPE_TIMEOUT_TERM_GRACE' => '-1' }, '1', 'TERM grace must be finite and non-negative'],
    [{ 'RECIPESWIPE_TIMEOUT_TERM_GRACE' => 'Infinity' }, '1', 'TERM grace must be finite and non-negative'],
    [{ 'RECIPESWIPE_TIMEOUT_KILL_GRACE' => 'NaN' }, '1', 'KILL grace must be finite and non-negative']
  ]

  invalid_configurations.each do |environment, timeout, diagnostic|
    output, status = Open3.capture2e(
      ENV.to_h.merge(environment),
      'ruby',
      '--disable-gems',
      'scripts/run-with-timeout.rb',
      timeout,
      'invalid duration',
      'true',
      chdir: ROOT
    )
    raise "watchdog accepted invalid duration #{timeout.inspect} with #{environment.inspect}" if status.success?
    raise "watchdog diagnostic missing: #{diagnostic}" unless output.include?(diagnostic)
  end
end

def valid_xcrun(path)
  write_executable(path, <<~'SH')
    #!/bin/sh
    printf '%s\n' '{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-0":[{"isAvailable":true,"name":"iPhone Contract","udid":"FAKE-UDID"}]}}'
  SH
end

def fake_xcodebuild(path)
  write_executable(path, <<~'SH')
    #!/bin/sh
    set -eu

    action="${1:-missing}"
    derived_data=""
    result_bundle=""
    previous=""
    for argument in "$@"; do
      case "$previous" in
        -derivedDataPath) derived_data="$argument" ;;
        -resultBundlePath) result_bundle="$argument" ;;
      esac
      previous="$argument"
    done

    [ -n "$derived_data" ] || exit 90
    mkdir -p "$derived_data"
    printf 'derived data fixture\n' > "$derived_data/fixture"
    if [ "$action" = test ] && [ -n "$result_bundle" ]; then
      mkdir -p "$result_bundle"
      printf 'result fixture\n' > "$result_bundle/fixture"
    fi

    if [ -n "${FAKE_RECORD_DIR:-}" ]; then
      printf '%s\t%s\t%s\n' "$action" "$derived_data" "$result_bundle" > "$FAKE_RECORD_DIR/$$.record"
    fi

    case "${FAKE_XCODEBUILD_MODE:-success}" in
      success) exit 0 ;;
      exit) exit "${FAKE_XCODEBUILD_EXIT_CODE:-37}" ;;
      hang)
        printf '%s\n' "$$" > "$FAKE_XCODEBUILD_PARENT_PID"
        trap '' HUP INT TERM
        sh -c 'trap "" HUP INT TERM; sleep 600' &
        child_pid=$!
        printf '%s\n' "$child_pid" > "$FAKE_XCODEBUILD_CHILD_PID"
        wait "$child_pid"
        ;;
      hang-parent-exits)
        printf '%s\n' "$$" > "$FAKE_XCODEBUILD_PARENT_PID"
        sh -c 'trap "" HUP INT TERM; sleep 600' &
        child_pid=$!
        printf '%s\n' "$child_pid" > "$FAKE_XCODEBUILD_CHILD_PID"
        wait "$child_pid"
        ;;
      descendant-survives-success)
        printf '%s\n' "$$" > "$FAKE_XCODEBUILD_PARENT_PID"
        sh -c 'trap "" HUP INT TERM; sleep 600' &
        child_pid=$!
        printf '%s\n' "$child_pid" > "$FAKE_XCODEBUILD_CHILD_PID"
        exit 0
        ;;
      *) exit 92 ;;
    esac
  SH
end

def base_env(directory, bin, fake_xcrun, fake_build)
  ENV.to_h.merge(
    'TMPDIR' => directory,
    'PATH' => "#{bin}:#{ENV.fetch('PATH')}",
    'XCRUN' => fake_xcrun,
    'XCODEBUILD' => fake_build,
    'RECIPESWIPE_SIMCTL_TIMEOUT' => '4',
    'RECIPESWIPE_XCODEBUILD_TIMEOUT' => '4',
    'RECIPESWIPE_TIMEOUT_TERM_GRACE' => '0.2',
    'RECIPESWIPE_TIMEOUT_KILL_GRACE' => '0.2'
  )
end

def temporary_runner_paths(directory)
  Dir.glob(File.join(directory, 'RecipeSwipe-{Build,DerivedData,TestResults,Simctl}.*'))
end

def assert_no_processes(pid_paths, executable)
  sleep 0.2
  pid_paths.each do |path|
    next unless File.exist?(path)

    pid = Integer(File.read(path), exception: false)
    raise "invalid pid recorded in #{path}" unless pid
    raise "orphaned process #{pid} from #{executable}" if alive?(pid)
  end

  pattern = Regexp.escape(executable)
  survivors = `ps -axo pid=,command=`.lines.select { |line| line.match?(pattern) }
  raise "orphaned command: #{survivors.join}" unless survivors.empty?
end

def assert_bounded_timeout(action, mode: 'hang')
  Dir.mktmpdir("recipeswipe-#{action}-timeout") do |directory|
    bin = File.join(directory, 'bin')
    FileUtils.mkdir_p(bin)
    xcrun = File.join(bin, 'xcrun')
    xcodebuild = File.join(bin, 'xcodebuild')
    valid_xcrun(xcrun)
    fake_xcodebuild(xcodebuild)
    parent_pid = File.join(directory, 'xcodebuild-parent.pid')
    child_pid = File.join(directory, 'xcodebuild-child.pid')
    env = base_env(directory, bin, xcrun, xcodebuild).merge(
      'FAKE_XCODEBUILD_MODE' => mode,
      'FAKE_XCODEBUILD_PARENT_PID' => parent_pid,
      'FAKE_XCODEBUILD_CHILD_PID' => child_pid
    )

    result = run_script(action, env, directory, action)
    raise "#{action} required external kill after #{result.elapsed.round(2)}s" if result.externally_timed_out
    unless result.status&.exitstatus == 124
      raise "#{action} timeout did not exit 124 (status=#{result.status.inspect}, output=#{result.output.inspect})"
    end
    raise "#{action} timeout diagnostic missing" unless result.output.include?("xcodebuild #{action} timed out")
    raise "#{action} timeout left temporary paths: #{temporary_runner_paths(directory).join(', ')}" unless temporary_runner_paths(directory).empty?
    assert_no_processes([parent_pid, child_pid], xcodebuild)
  end
end

def assert_exit_code_and_cleanup(action)
  Dir.mktmpdir("recipeswipe-#{action}-exit") do |directory|
    bin = File.join(directory, 'bin')
    FileUtils.mkdir_p(bin)
    xcrun = File.join(bin, 'xcrun')
    xcodebuild = File.join(bin, 'xcodebuild')
    valid_xcrun(xcrun)
    fake_xcodebuild(xcodebuild)
    env = base_env(directory, bin, xcrun, xcodebuild).merge(
      'FAKE_XCODEBUILD_MODE' => 'exit',
      'FAKE_XCODEBUILD_EXIT_CODE' => '37'
    )

    result = run_script(action, env, directory, "#{action}-exit")
    raise "#{action} exit probe required external kill" if result.externally_timed_out
    unless result.status&.exitstatus == 37
      raise "#{action} did not propagate exit 37 (status=#{result.status.inspect}, output=#{result.output.inspect})"
    end
    raise "#{action} failure left temporary paths: #{temporary_runner_paths(directory).join(', ')}" unless temporary_runner_paths(directory).empty?
  end
end

def assert_success_reaps_descendant(action)
  Dir.mktmpdir("recipeswipe-#{action}-success-descendant") do |directory|
    bin = File.join(directory, 'bin')
    FileUtils.mkdir_p(bin)
    xcrun = File.join(bin, 'xcrun')
    xcodebuild = File.join(bin, 'xcodebuild')
    valid_xcrun(xcrun)
    fake_xcodebuild(xcodebuild)
    parent_pid = File.join(directory, 'xcodebuild-parent.pid')
    child_pid = File.join(directory, 'xcodebuild-child.pid')
    env = base_env(directory, bin, xcrun, xcodebuild).merge(
      'FAKE_XCODEBUILD_MODE' => 'descendant-survives-success',
      'FAKE_XCODEBUILD_PARENT_PID' => parent_pid,
      'FAKE_XCODEBUILD_CHILD_PID' => child_pid
    )

    result = run_script(action, env, directory, "#{action}-success-descendant")
    raise "#{action} descendant success required external kill" if result.externally_timed_out
    raise "#{action} descendant success did not preserve exit 0" unless result.status&.success?
    raise "#{action} descendant cleanup was not bounded (#{result.elapsed.round(2)}s)" if result.elapsed >= 12
    raise "#{action} descendant success left temporary paths: #{temporary_runner_paths(directory).join(', ')}" unless temporary_runner_paths(directory).empty?
    assert_no_processes([parent_pid, child_pid], xcodebuild)
  ensure
    if File.exist?(parent_pid)
      process_group = Integer(File.read(parent_pid), exception: false)
      begin
        Process.kill('KILL', -process_group) if process_group
      rescue Errno::ESRCH
        nil
      end
    end
  end
end

def assert_signal_cleanup(action)
  Dir.mktmpdir("recipeswipe-#{action}-signal") do |directory|
    bin = File.join(directory, 'bin')
    FileUtils.mkdir_p(bin)
    xcrun = File.join(bin, 'xcrun')
    xcodebuild = File.join(bin, 'xcodebuild')
    valid_xcrun(xcrun)
    fake_xcodebuild(xcodebuild)
    parent_pid = File.join(directory, 'xcodebuild-parent.pid')
    child_pid = File.join(directory, 'xcodebuild-child.pid')
    stdout_path = File.join(directory, 'signal.stdout')
    stderr_path = File.join(directory, 'signal.stderr')
    env = base_env(directory, bin, xcrun, xcodebuild).merge(
      'RECIPESWIPE_XCODEBUILD_TIMEOUT' => '30',
      'FAKE_XCODEBUILD_MODE' => 'hang',
      'FAKE_XCODEBUILD_PARENT_PID' => parent_pid,
      'FAKE_XCODEBUILD_CHILD_PID' => child_pid
    )
    runner_pid = spawn_runner(action, env, stdout_path, stderr_path)

    begin
      Timeout.timeout(3) { sleep 0.05 until File.exist?(parent_pid) }
      Process.kill('TERM', runner_pid)
      _, status = Timeout.timeout(20) { Process.wait2(runner_pid) }
      expected_signal_exit = status.termsig == Signal.list.fetch('TERM') || status.exitstatus == 128 + Signal.list.fetch('TERM')
      raise "#{action} did not preserve TERM status" unless expected_signal_exit
    rescue Timeout::Error
      terminate_group(runner_pid)
      output = [File.read(stdout_path), File.read(stderr_path)].join
      raise "#{action} did not terminate after TERM (output=#{output.inspect})"
    ensure
      terminate_group(runner_pid) if alive?(runner_pid)
    end

    raise "#{action} signal left temporary paths: #{temporary_runner_paths(directory).join(', ')}" unless temporary_runner_paths(directory).empty?
    assert_no_processes([parent_pid, child_pid], xcodebuild)
  end
end

def assert_parallel_isolation
  Dir.mktmpdir('recipeswipe-parallel-isolation') do |directory|
    bin = File.join(directory, 'bin')
    records = File.join(directory, 'records')
    FileUtils.mkdir_p([bin, records])
    xcrun = File.join(bin, 'xcrun')
    xcodebuild = File.join(bin, 'xcodebuild')
    valid_xcrun(xcrun)
    fake_xcodebuild(xcodebuild)
    env = base_env(directory, bin, xcrun, xcodebuild).merge(
      'FAKE_XCODEBUILD_MODE' => 'success',
      'FAKE_RECORD_DIR' => records
    )

    runs = %i[build build test test].each_with_index.map do |action, index|
      Thread.new { run_script(action, env, directory, "parallel-#{index}") }
    end.map(&:value)

    raise 'parallel runner required external kill' if runs.any?(&:externally_timed_out)
    unless runs.all? { |run| run.status&.success? }
      details = runs.map { |run| "status=#{run.status.inspect} output=#{run.output.inspect}" }.join('; ')
      raise "parallel runner returned nonzero: #{details}"
    end

    entries = Dir.glob(File.join(records, '*.record')).map { |path| File.read(path).chomp.split("\t", -1) }
    raise "expected 4 parallel records, got #{entries.length}" unless entries.length == 4
    derived_paths = entries.map { |entry| entry.fetch(1) }
    raise 'parallel DerivedData paths were not unique' unless derived_paths.uniq.length == 4
    test_bundles = entries.select { |entry| entry.fetch(0) == 'test' }.map { |entry| entry.fetch(2) }
    raise 'test result bundle paths were missing or shared' unless test_bundles.length == 2 && test_bundles.all? { |path| !path.empty? } && test_bundles.uniq.length == 2
    raise "parallel success left temporary paths: #{temporary_runner_paths(directory).join(', ')}" unless temporary_runner_paths(directory).empty?
  end
end

def assert_discovery_signal_cleanup
  Dir.mktmpdir('recipeswipe-discovery-signal') do |directory|
    bin = File.join(directory, 'bin')
    FileUtils.mkdir_p(bin)
    xcrun = File.join(bin, 'xcrun')
    parent_pid = File.join(directory, 'xcrun-parent.pid')
    child_pid = File.join(directory, 'xcrun-child.pid')
    stdout_path = File.join(directory, 'signal.stdout')
    stderr_path = File.join(directory, 'signal.stderr')
    write_executable(xcrun, <<~SH)
      #!/bin/sh
      printf '%s\n' "$$" > #{Shellwords.escape(parent_pid)}
      trap '' HUP INT TERM
      sh -c 'trap "" HUP INT TERM; sleep 600' &
      printf '%s\n' "$!" > #{Shellwords.escape(child_pid)}
      wait
    SH
    env = ENV.to_h.merge(
      'TMPDIR' => directory,
      'RECIPESWIPE_SIMCTL_TIMEOUT' => '30',
      'RECIPESWIPE_TIMEOUT_TERM_GRACE' => '0.2',
      'RECIPESWIPE_TIMEOUT_KILL_GRACE' => '0.2',
      'XCRUN' => xcrun
    )
    runner_pid = spawn_runner(:test, env, stdout_path, stderr_path)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    begin
      Timeout.timeout(3) { sleep 0.05 until File.exist?(parent_pid) }
      Process.kill('TERM', runner_pid)
      _, status = Timeout.timeout(20) { Process.wait2(runner_pid) }
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      expected_signal_exit = status.termsig == Signal.list.fetch('TERM') || status.exitstatus == 128 + Signal.list.fetch('TERM')
      raise 'simulator discovery did not preserve TERM status' unless expected_signal_exit
      raise "simulator discovery signal cleanup was delayed until its timeout (#{elapsed.round(2)}s)" if elapsed >= 25
    rescue Timeout::Error
      terminate_group(runner_pid)
      raise 'simulator discovery did not terminate promptly after TERM'
    ensure
      terminate_group(runner_pid) if alive?(runner_pid)
    end

    raise "discovery signal left temporary paths: #{temporary_runner_paths(directory).join(', ')}" unless temporary_runner_paths(directory).empty?
    assert_no_processes([parent_pid, child_pid], xcrun)
  end
end

failures = []

begin
  assert_default_time_bounds
rescue StandardError => error
  failures << error.message
end

begin
  assert_watchdog_reaps_success_descendant
rescue StandardError => error
  failures << error.message
end

begin
  assert_watchdog_treats_eperm_probe_as_alive
rescue StandardError => error
  failures << error.message
end

begin
  assert_watchdog_rejects_unbounded_durations
rescue StandardError => error
  failures << error.message
end

begin
  Dir.mktmpdir('recipeswipe-discovery-timeout') do |directory|
    bin = File.join(directory, 'bin')
    FileUtils.mkdir_p(bin)
    xcrun = File.join(bin, 'xcrun')
    parent_pid = File.join(directory, 'xcrun-parent.pid')
    child_pid = File.join(directory, 'xcrun-child.pid')
    write_executable(xcrun, <<~SH)
      #!/bin/sh
      printf '%s\n' "$$" > #{Shellwords.escape(parent_pid)}
      trap '' HUP INT TERM
      sh -c 'trap "" HUP INT TERM; sleep 600' &
      printf '%s\n' "$!" > #{Shellwords.escape(child_pid)}
      wait
    SH
    env = ENV.to_h.merge(
      'TMPDIR' => directory,
      'RECIPESWIPE_SIMCTL_TIMEOUT' => '2',
      'RECIPESWIPE_TIMEOUT_TERM_GRACE' => '0.2',
      'RECIPESWIPE_TIMEOUT_KILL_GRACE' => '0.2',
      'XCRUN' => xcrun
    )

    result = run_script(:test, env, directory, 'discovery')
    raise 'simulator discovery required external kill' if result.externally_timed_out
    raise 'simulator discovery timeout did not exit 124' unless result.status&.exitstatus == 124
    raise 'simulator discovery timeout diagnostic missing' unless result.output.include?('simctl list devices timed out')
    raise "discovery timeout left temporary paths: #{temporary_runner_paths(directory).join(', ')}" unless temporary_runner_paths(directory).empty?
    assert_no_processes([parent_pid, child_pid], xcrun)
  end
rescue StandardError => error
  failures << error.message
end

%i[build test].each do |action|
  begin
    assert_bounded_timeout(action)
  rescue StandardError => error
    failures << error.message
  end

  begin
    assert_bounded_timeout(action, mode: 'hang-parent-exits')
  rescue StandardError => error
    failures << "#{action} parent-exit cleanup: #{error.message}"
  end

  begin
    assert_exit_code_and_cleanup(action)
  rescue StandardError => error
    failures << error.message
  end

  begin
    assert_success_reaps_descendant(action)
  rescue StandardError => error
    failures << error.message
  end

  begin
    assert_signal_cleanup(action)
  rescue StandardError => error
    failures << error.message
  end
end

begin
  assert_discovery_signal_cleanup
rescue StandardError => error
  failures << error.message
end

begin
  assert_parallel_isolation
rescue StandardError => error
  failures << error.message
end

abort(failures.join("\n")) unless failures.empty?

puts 'xcode runner contract tests passed'
