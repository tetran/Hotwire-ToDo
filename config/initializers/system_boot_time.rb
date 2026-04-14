module SystemBootTime
  MONOTONIC_STARTED_AT = Process.clock_gettime(Process::CLOCK_MONOTONIC)
end
