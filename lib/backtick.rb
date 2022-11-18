# lib/backtick: Add exception handling support for the backtick command block

# In ruby, the backtick function can only be overridden within a module.
#
# In order to override the backtick function, we need to create a module
# for the new function and export all functions under this module to global scope.
module Backtick
  def `(cmd)
    cmdName   = cmd.partition[0] # extract command name, used in error message below
    processIO = popen(['bash', '-c', cmd], 'r')
    output    = processIO.read

    _, exitstatus = Process.wait2 # wait for command process, get exit code
    processIO.close               # close pipe connecting the process

    case exitstatus
    when 0   # success
      return output
    when 127 # command not exist
      raise Errno::ENOENT, "No such file or directory - #{cmdName}"
    else     # other error codes (except 127)
      raise RuntimeError, "Command failed with exit #{exitstatus}: #{cmdName}"
    end
  end
end

# import the module to global scope
include Backtick