#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'shellwords'
require 'tmpdir'
require 'timeout'

ROOT = File.expand_path('..', __dir__)
SCRIPT = File.join(ROOT, 'scripts/xcode-test.sh')

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
end

def run_script_with_guard(env, stdout_path, stderr_path)
  pid = Process.spawn(
    env,
    'bash',
    SCRIPT,
    out: stdout_path,
    err: stderr_path,
    pgroup: true
  )

  status = nil
  Timeout.timeout(8) do
    _, status = Process.wait2(pid)
  end
  status
rescue Timeout::Error
  terminate_group(pid) if pid
  abort('xcode-test.sh did not bound wedged simctl list devices discovery')
end

Dir.mktmpdir('recipeswipe-runner-contract') do |directory|
  bin = File.join(directory, 'bin')
  FileUtils.mkdir_p(bin)
  fake_xcrun = File.join(bin, 'xcrun')
  parent_pid = File.join(directory, 'xcrun-parent.pid')
  child_pid = File.join(directory, 'xcrun-child.pid')
  stdout_path = File.join(directory, 'stdout')
  stderr_path = File.join(directory, 'stderr')

  fake_xcrun_source = <<~'SH'
    #!/bin/sh
    echo "$$" > __PARENT_PID__
    trap '' TERM
    sleep 600 &
    echo "$!" > __CHILD_PID__
    wait
  SH
  fake_xcrun_source = fake_xcrun_source
    .sub('__PARENT_PID__', Shellwords.escape(parent_pid))
    .sub('__CHILD_PID__', Shellwords.escape(child_pid))
  File.write(fake_xcrun, fake_xcrun_source)
  File.chmod(0o755, fake_xcrun)

  env = ENV.to_h.merge(
    'TMPDIR' => directory,
    'RECIPESWIPE_SIMCTL_TIMEOUT' => '2',
    'XCRUN' => fake_xcrun
  )

  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  status = run_script_with_guard(env, stdout_path, stderr_path)
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  output = [File.read(stdout_path), File.read(stderr_path)].join

  abort('expected wedged simulator discovery to exit nonzero') if status.success?
  abort("expected bounded simulator discovery, took #{elapsed.round(2)}s") if elapsed >= 7
  abort('expected timeout diagnostic for simulator discovery') unless output.include?('simctl list devices timed out')

  sleep 0.2
  recorded_pids = [parent_pid, child_pid].each_with_object([]) do |path, pids|
    next unless File.exist?(path)

    pid = Integer(File.read(path), exception: false)
    abort("invalid pid recorded in #{path}") unless pid
    pids << pid
  end
  recorded_pids.each do |pid|
    abort("orphaned fake xcrun process #{pid}") if alive?(pid)
  end

  fake_path_pattern = Regexp.escape(fake_xcrun)
  surviving_fake_processes = `ps -axo pid=,command=`.lines.select do |line|
    line.match?(fake_path_pattern) && !line.include?('ps -axo')
  end
  abort("orphaned fake xcrun command: #{surviving_fake_processes.join}") unless surviving_fake_processes.empty?
end

puts 'xcode runner contract tests passed'
