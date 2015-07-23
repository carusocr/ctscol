# encoding: utf-8
#testing

class LdcTestController < Adhearsion::CallController

  attr_accessor :number, :attempt

  def run
    answer
    play '/var/lib/asterisk/sounds/en/conf-onlyperson.gsm'
    hangup
  end

end

class SayTime < Adhearsion::CallController

  def run
    answer
    t = Time.now
    date = t.to_date
    date_format = 'ABdY'
    #execute "SayUnixTime", t.to_i, date_format
    #play_time date, :format => date_format
    result = ask '/var/lib/asterisk/sounds/en/conf-getpin.gsm', terminator: '#'
    if result.response.to_i == 4444
      play_digits(result.response)
      play '/var/lib/asterisk/sounds/en/auth-thankyou.gsm'
    else
      play_digits(result.response)
      play '/var/lib/asterisk/sounds/en/auth-incorrect.gsm'
    end
    hangup
  end

end
