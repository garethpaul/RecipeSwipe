#!/usr/bin/env ruby
# frozen_string_literal: true

seconds_text = ARGV.shift
label = ARGV.shift

abort('usage: run-with-timeout.rb seconds label command [args...]') if seconds_text.nil? || label.nil? || ARGV.empty?

timeout = Float(seconds_text)
abort('timeout must be positive') unless timeout.positive?

term_grace = Float(ENV.fetch('RECIPESWIPE_TIMEOUT_TERM_GRACE', '0.5'))
kill_grace = Float(ENV.fetch('RECIPESWIPE_TIMEOUT_KILL_GRACE', '0.5'))
received_signal = nil

def kill_process_group(pid, signal)
  Process.kill(signal, -pid)
rescue Errno::ESRCH
  nil
end

def process_group_alive?(pid)
  Process.kill(0, -pid)
  true
rescue Errno::ESRCH
  false
end

def wait_for_exit(pid, seconds)
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
  loop do
    waited, status = Process.waitpid2(pid, Process::WNOHANG)
    return status if waited
    return nil if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

    sleep 0.05
  end
rescue Errno::ECHILD
  nil
end

def terminate_process_group(pid, signal, term_grace, kill_grace)
  kill_process_group(pid, signal)
  status = wait_for_exit(pid, term_grace)
  return status unless process_group_alive?(pid)

  kill_process_group(pid, 'KILL')
  status ||= wait_for_exit(pid, kill_grace)
  status
end

%w[HUP INT TERM].each do |signal|
  Signal.trap(signal) { received_signal = signal }
end

child_pid = Process.spawn(*ARGV, pgroup: true)
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
status = nil

loop do
  waited, status = Process.waitpid2(child_pid, Process::WNOHANG)
  break if waited || received_signal
  break if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

  sleep 0.05
end

if status
  exit(status.exitstatus || (128 + status.termsig))
end

if received_signal
  terminate_process_group(child_pid, received_signal, term_grace, kill_grace)
  exit(128 + Signal.list.fetch(received_signal))
end

warn "#{label} timed out after #{timeout.to_i}s"
terminate_process_group(child_pid, 'TERM', term_grace, kill_grace)

exit 124
