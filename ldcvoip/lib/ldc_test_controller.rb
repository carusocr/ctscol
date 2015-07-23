# encoding: utf-8

class LdcTestController < Adhearsion::CallController

  attr_accessor :number, :attempt

  def run
    answer
    play '/var/lib/asterisk/sounds/en/conf-onlyperson.gsm'
    hangup
  end

end
