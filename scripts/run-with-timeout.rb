#!/usr/bin/env ruby
# frozen_string_literal: true

seconds_text = ARGV.shift
label = ARGV.shift

abort('usage: run-with-timeout.rb seconds label command [args...]') if seconds_text.nil? || label.nil? || ARGV.empty?

timeout = Float(seconds_text)
abort('timeout must be positive') unless timeout.positive?

child_pid = nil
term_grace = Float(ENV.fetch('RECIPESWIPE_TIMEOUT_TERM_GRACE', '0.5'))
kill_grace = Float(ENV.fetch('RECIPESWIPE_TIMEOUT_KILL_GRACE', '0.5'))

def kill_process_group(pid, signal)
  Process.kill(signal, -pid)
rescue Errno::ESRCH
  nil
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

%w[HUP INT TERM].each do |signal|
  Signal.trap(signal) do
    kill_process_group(child_pid, signal) if child_pid
    exit(128 + Signal.list.fetch(signal))
  end
end

child_pid = Process.spawn(*ARGV, pgroup: true)
status = wait_for_exit(child_pid, timeout)

if status
  exit(status.exitstatus || (128 + status.termsig))
end

warn "#{label} timed out after #{timeout.to_i}s"
kill_process_group(child_pid, 'TERM')
status = wait_for_exit(child_pid, term_grace)
unless status
  kill_process_group(child_pid, 'KILL')
  wait_for_exit(child_pid, kill_grace)
end

exit 124
