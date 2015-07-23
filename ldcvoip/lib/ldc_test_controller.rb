# encoding: utf-8

class LdcTestController < Adhearsion::CallController
  def run
    answer
    result = ask "Enter PIN", terminator: '#'
  end
end
